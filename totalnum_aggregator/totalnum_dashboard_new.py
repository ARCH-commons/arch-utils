import sqlite3

import dash
import dash_core_components as dcc
import dash_html_components as html
import pandas as pd
import plotly.graph_objs as go
from dash.dependencies import Input, Output, State

# Experimental visualization of totalnum data using the output of totalnum_builddb. Uses dash, presently only for local deployment.
# by Jeff Klann, PHD 9-2018

# Initialize dashboard-wide globals
app = dash.Dash()
basedir = "/Users/jklann/Google Drive/SCILHS Phase II/Committee, Cores, Panels/Informatics & Technology Core/totalnums/joined"
conn = sqlite3.connect(basedir + '/totalnums.db',detect_types=sqlite3.PARSE_DECLTYPES) # Parameter converts datetimes
c = conn.cursor()
zoom_clix = 0
unzoom_clix = 0
c.execute("select min(c_hlevel) from bigfullname")
hlevel = c.fetchone()[0]
minhlevel = hlevel
c.execute("select c_fullname from bigfullname where c_hlevel=? limit 1", str(hlevel))
pathstart = c.fetchone()[0]
pathstart = pathstart[0:pathstart[1:].find('\\') + 1]
path = [pathstart]
site = 'sum'
sites=pd.read_sql("select distinct site from totalnums",conn).site.tolist()


instruction = """# How to use
1. Optionally choose a site from the dropdown
2. The options in the checkboxes start at the top level of the ontology. To navigate down the tree, check one box, click the button, and its children are displayed.
3. To display graphs, check boxes as desired. Temporal totalnum graphs will appear below.
"""

# App Layout
app.layout = html.Div([
    dcc.Markdown(instruction),
    dcc.Dropdown(id='site', options=list(map(lambda a: {'label': a, 'value': a}, sites))),
    html.Table([html.Tr([
        html.Td(html.Div([
            dcc.Checklist(id='items', options=[{'label': 'No options', 'value': 'none'}], values=[],
                          labelStyle={'display': 'block'}),
            html.Button('<--', id='unzoom'),
            html.Button('-->', id='zoom')])),
        html.Td(dcc.Graph(id='hlevel_graph'))])]),

    html.Div('errmsghere-todo-', id='msg0'),
    html.Br()
])

# This callback just clears the checkboxes when the button is pressed, otherwise they are never cleared when the
# options are updated and hidden checkboxes accumulate in the state.
@ app.callback(
    Output('items', 'values'),
    [Input('zoom', 'n_clicks'), Input('unzoom', 'n_clicks')]
)
def clearTheChecks(clix, unclix):
    return []


# This is the callback when someone clicks the zoom button, which moves down the hierarchy
# It also needs to handle the base case of just setting the state of the items.
@app.callback(
    Output('items', 'options'),
    [Input('zoom', 'n_clicks'), Input('unzoom', 'n_clicks')],
    [State('items', 'values'), State('items', 'options')]
)
def cbNavigate(clix, unclix, checks, options):
    global zoom_clix, hlevel, path, tndf, minhlevel, unzoom_clix, conn, site
    # If slider was moved but not button click, or callback called on startup, or multiple checked or nothing checked
    unclix = 0 if unclix == None else unclix
    if unclix != unzoom_clix:
        unzoom_clix = unclix
        if hlevel > minhlevel:
            unzoom_clix = unclix
            hlevel = hlevel - 1
            path = path[:-1]
            print("Unzoom:" + str(path))
    elif len(checks) == 0 or len(checks) > 1:
        None
    elif clix != zoom_clix:
        zoom_clix = clix
        hlevel = hlevel + 1
        path.append(checks[0][checks[0][:-1].rfind('\\') + 1:-1])
        print("Zoom:" + str(path))

    # Compute the items for the checkboxes and return
    sql = "select distinct c_fullname AS value,c_name AS label from totalnums t inner join bigfullname b on t.fullname_int=b.fullname_int where c_hlevel='%s' and site='%s' and c_fullname like '%s'" % (
    str(hlevel), site, '\\'.join(path) + '\\%')
    items = pd.read_sql_query(sql, conn).to_dict('records')
    return items


# This callback draws the graph whenever checkboxes change or site is changed
@app.callback(
    Output('hlevel_graph', 'figure'),
    [Input('items', 'values'), Input('site', 'value')])
def cbGraph(checks, isite):
    global hlevel, conn, site

    if (site != isite):
        # Site changed!
        ssite = isite if isite else 'sum'
        print("New site selected:" + ssite)
        site = ssite

    # Get just the available data in the df
    sql = "select c_fullname,refresh_date,c_name,c from totalnums t inner join bigfullname b on t.fullname_int=b.fullname_int where c_hlevel='%s' and site='%s' and c_fullname like '%s'" % (
    hlevel, site, '\\'.join(path) + '\\%')
    dfsub = pd.read_sql_query(sql, conn)

    traces = []
    for n in checks:
        xf = dfsub[dfsub.c_fullname == n]
        if len(xf) > 0:
            traces.append(
                go.Scatter(x=xf['refresh_date'], y=xf['c'], text=xf.iloc[0, :].c_name, name=xf.iloc[0, :].c_name,
                           marker={'size': 15}, mode='line'))
    return {'data': traces}

app.run_server(debug=False)