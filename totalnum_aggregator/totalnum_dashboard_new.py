import json
import sqlite3

import dash
import dash_core_components as dcc
import dash_html_components as html
import pandas as pd
import plotly.graph_objs as go
from dash.dependencies import Input, Output, State

# Experimental visualization of totalnum data using the output of totalnum_builddb. Uses dash.
# Now supports deployment, multiple sessions, and gunicorn!
# To run with gunicorn: gunicorn 'totalnum_dashboard_new.py:initApp("/path/to/database")'
# by Jeff Klann, PHD 9-2018


instruction = """# How to use
1. Optionally choose a site from the dropdown
2. The options in the checkboxes start at the top level of the ontology. To navigate down the tree, check one box, click the button, and its children are displayed.
3. To display graphs, check boxes as desired. Temporal totalnum graphs will appear below.
"""
app = dash.Dash()

# App Layout
app.layout = html.Div([
    dcc.Markdown(instruction),
    dcc.Dropdown(id='site', options=[]),
    html.Table([html.Tr([
        html.Td(html.Div([
            dcc.Checklist(id='items', options=[{'label': 'No options', 'value': 'none'}], values=[],
                          labelStyle={'display': 'block'}),
            html.Button('<--', id='unzoom'),
            html.Button('-->', id='zoom')])),
        html.Td(dcc.Graph(id='hlevel_graph'))])]),

    html.Div('errmsghere-todo-', id='msg0'),
    html.Div('app_state', id='app_state'),
    html.Br()
])


def initApp(db="/Users/jklann/Google Drive/SCILHS Phase II/Committee, Cores, Panels/Informatics & Technology Core/totalnums/joined/totalnums.db"):
    global conn,app
    # Initialize dashboard-wide globals
    conn = sqlite3.connect(db,detect_types=sqlite3.PARSE_DECLTYPES)  # Parameter converts datetimes

    # Get site list
    sites = pd.read_sql("select distinct site from totalnums", conn).site.tolist()
    options = list(map(lambda a: {'label': a, 'value': a}, sites))
    app.layout['site'].options = options

    return app.server

# This callback just clears the checkboxes when the button is pressed, otherwise they are never cleared when the
# options are updated and hidden checkboxes accumulate in the state.
@ app.callback(
    Output('items', 'values'),
    [Input('zoom', 'n_clicks'), Input('unzoom', 'n_clicks')]
)
def clearTheChecks(clix, unclix):
    return []


# Run this when the app starts to set the state of things
# Updates the state JSON when a button is clicked or the dropdown is used
@app.callback(
    Output('app_state','children'),
    [Input('zoom', 'n_clicks'), Input('unzoom', 'n_clicks'), Input('site', 'value')],
    [State('items', 'values'), State('items', 'options'),State('app_state','children')]
)
def cbController(zoomclix,unzoomclix,site,checks,options,appstate):
    global conn
    if appstate=='app_state':
        # Initialize the app
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
        app_state = {'action':'','zoom_clix': 0, 'unzoom_clix': 0, 'hlevel':hlevel,'minhlevel': minhlevel, 'path': path, 'site': site}
        return json.dumps(app_state)

    appstatedict = json.loads(appstate)

    # If slider was moved but not button click, or callback called on startup, or multiple checked or nothing checked
    unclix = 0 if unzoomclix is None else unzoomclix
    clix=0 if zoomclix is None else zoomclix

    if (site and site != appstatedict['site']):
        # Site changed!
        appstatedict['site'] = site if site else 'sum'
        print("New site selected:" + site)
        print("Controller - New Site selected")
        appstatedict['action']='site'
    if unclix != appstatedict['unzoom_clix']:
        appstatedict['unzoom_clix'] = unclix
        if appstatedict['hlevel'] > appstatedict['minhlevel']:
            appstatedict['hlevel'] = appstatedict['hlevel'] - 1
            appstatedict['path'] = appstatedict['path'][:-1]
            appstatedict['action']='unzoom'
            print("Controller - Unzoom:" + str(appstatedict['path']))
    elif len(checks) == 0 or len(checks) > 1:
        appstatedict['action']='none'
        print("Controller - no action")
    elif appstatedict['zoom_clix'] != clix:
        appstatedict['zoom_clix'] = clix
        appstatedict['hlevel'] = appstatedict['hlevel'] + 1
        appstatedict['path'].append(checks[0][checks[0][:-1].rfind('\\') + 1:-1])
        appstatedict['action']='zoom'
        print("Controller - Zoom:" + str(appstatedict['path']))

    return json.dumps(appstatedict)


# This is the callback when someone clicks the zoom button, which moves down the hierarchy
# It also needs to handle the base case of just setting the state of the items.
@app.callback(
    Output('items', 'options'),
#    [Input('zoom', 'n_clicks'), Input('unzoom', 'n_clicks')],
    [Input('app_state','children')],
    [State('items', 'values'), State('items', 'options')]
)
def cbNavigate(state, checks, options):
    global conn
    if (state=='app_state'): return options
    appstatedict = json.loads(state)

    if appstatedict['action'] in ('zoom','unzoom',''):
        # Compute the items for the checkboxes and return
        sql = "select distinct c_fullname AS value,c_name AS label from totalnums t inner join bigfullname b on t.fullname_int=b.fullname_int where c_hlevel='%s' and site='%s' and c_fullname like '%s'" % (
         str(appstatedict['hlevel']), appstatedict['site'], '\\'.join(appstatedict['path']) + '\\%')
        items = pd.read_sql_query(sql, conn).to_dict('records')
        return items

    return options

# This callback draws the graph whenever checkboxes change or site is changed
@app.callback(
    Output('hlevel_graph', 'figure'),
    [Input('items', 'values'), Input('site', 'value')],
    [State('app_state','children')]
)
def cbGraph(checks, isite,state):
    global conn
    if (state=='app_state'): return {}
    appstatedict = json.loads(state)


    # Get just the available data in the df
    sql = "select c_fullname,refresh_date,c_name,c from totalnums t inner join bigfullname b on t.fullname_int=b.fullname_int where c_hlevel='%s' and site='%s' and c_fullname like '%s'" % (
     appstatedict['hlevel'], isite if isite else appstatedict['site'], '\\'.join(appstatedict['path']) + '\\%')
    dfsub = pd.read_sql_query(sql, conn)

    traces = []
    for n in checks:
        xf = dfsub[dfsub.c_fullname == n]
        if len(xf) > 0:
            traces.append(
                go.Scatter(x=xf['refresh_date'], y=xf['c'], text=xf.iloc[0, :].c_name, name=xf.iloc[0, :].c_name,
                           marker={'size': 15}, mode='line'))
    return {'data': traces}

if __name__=='__main__':
    initApp("/Users/jklann/Google Drive/SCILHS Phase II/Committee, Cores, Panels/Informatics & Technology Core/totalnums/joined/totalnums.db")
    app.run_server(debug=False)