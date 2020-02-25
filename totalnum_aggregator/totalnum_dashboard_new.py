import json
import sqlite3

import time
import networkx as nx
import dash
import dash_auth
import dash_core_components as dcc
import dash_html_components as html
import pandas as pd
import plotly.graph_objs as go
from dash.dependencies import Input, Output, State

# Experimental visualization of totalnum data using the output of totalnum_builddb. Uses dash.
# Now supports deployment, multiple sessions, and gunicorn!
# To run with gunicorn: GUNICORN_CMD_ARGS="--bind=0.0.0.0" gunicorn 'totalnum_dashboard_new:initApp("/path/to/database")'
# by Jeff Klann, PHD 9-2018


instruction = """# Totalnum Dashboard
1. Optionally choose a site from the dropdown
2. The options in the checkboxes start at the top level of the ontology. To navigate down the tree, check one box, click the right arrow button, and its children are displayed. Likewise, to navigate up the tree, click the left arrow button.
3. Graphs:
   * Top-left: Check boxes as desired. Temporal totalnum will appear below, showing the trend in # patients at each refresh.
   * Top-right: Check boxes as desired. Site-by-site totalnum will appear, showing the breakdown in # patients per site (max among all refreshes).
   * Bottom: Click left or right arrow as desired. Network graph of current ontology level and its children are displayed, with node size indicating the totalnum per item (at selected site, max among all refreshes).
"""
app = dash.Dash()

# App Auth
# Set username and password in local install, instead of hello world
auth = dash_auth.BasicAuth(
    app,
    [['hello','world']]
)


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
        html.Td(dcc.Graph(id='hlevel_graph')),html.Td(dcc.Graph(id='bars_graph'))])
     #html.Tr([html.Td(),html.Td(dcc.Graph(id='tree_graph'))])
    ]),
    dcc.Graph(id='tree_graph'),
    html.Div('written by Jeffrey Klann, PhD 10-2018'), html.Br(),
#    html.Div('errmsghere-todo-', id='msg0'),
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
    start = time.time()
    appstatedict = json.loads(state)


    # Get just the available data in the df
    sql = "select distinct c_fullname,refresh_date,c_name,c from totalnums t inner join bigfullname b on t.fullname_int=b.fullname_int where c_hlevel='%s' and site='%s' and c_fullname like '%s'" % (
     appstatedict['hlevel'], isite if isite else appstatedict['site'], '\\'.join(appstatedict['path']) + '\\%')
    print(sql)
    dfsub = pd.read_sql_query(sql, conn)

    traces = []
    ymax = 0
    for n in checks:
        xf = dfsub[dfsub.c_fullname == n]
        if len(xf) > 0:
            traces.append(
                go.Scatter(x=xf['refresh_date'], y=xf['c'], text=xf.iloc[0, :].c_name, name=xf.iloc[0, :].c_name,
                           marker={'size': 15}, mode='lines+markers'))
            ymax=max(ymax,xf.groupby(by='c_fullname').max()['c'].values[0]) # Fix 11-19 - put the legend in the right place
            Cstd=xf['c'].std()
            Cmean=xf['c'].mean()
            Clow = Cmean - 3*Cstd
            if Clow<0: Clow=0
            traces.append(go.Scatter(x=[xf['refresh_date'].min(),xf['refresh_date'].max()],y=[Cmean,Cmean],name='mean of '+xf.iloc[0,:].c_name,mode='lines')) # Mean
            traces.append(go.Scatter(x=[xf['refresh_date'].min(), xf['refresh_date'].max()], y=[Cmean+3*Cstd, Cmean+3*Cstd],
                                    name='high control of ' + xf.iloc[0, :].c_name, mode='lines'))
            traces.append(go.Scatter(x=[xf['refresh_date'].min(), xf['refresh_date'].max()], y=[Clow, Clow],
                                     name='low control of ' + xf.iloc[0, :].c_name, mode='lines'))
    print("Graph time:"+str(time.time()-start))
    layout =  {'legend':{'x':0,'y':ymax}}
    return {'data': traces, 'layout': layout}


# This callback draws the bar graph whenever checkboxes change
@app.callback(
    Output('bars_graph', 'figure'),
    [Input('items', 'values')],
    [State('app_state','children')]
)
def cbBars(checks,state):
    global conn
    if (state=='app_state'): return {}
    start = time.time()
    appstatedict = json.loads(state)

    # Get just the available data in the df
    sql = "select distinct c_fullname,site,c_name,max(c) c from totalnums t inner join bigfullname b on t.fullname_int=b.fullname_int where site!='sum' and c_hlevel='%s' and c_fullname like '%s' group by c_fullname,site,c_name" % (
     appstatedict['hlevel'], '\\'.join(appstatedict['path']) + '\\%')
    dfsub = pd.read_sql_query(sql, conn)

    traces = []
    for n in checks:
        xf = dfsub[dfsub.c_fullname == n]
        if len(xf) > 0:
            traces.append(
                go.Bar(x=xf['site'], y=xf['c'], text=xf.iloc[0, :].c_name, name=xf.iloc[0, :].c_name))
                          # marker={'size': 15}, mode='lines+markers'))
    print("Bar time:"+str(time.time()-start))
    return {'data': traces}


# This callback draws the tree whenever button is clicked or site is changed
@app.callback(
    Output('tree_graph', 'figure'),
   # [Input('zoom', 'n_clicks'), Input('unzoom', 'n_clicks'), Input('site', 'value')],
    [Input('app_state','children')]
)
def cbTree(state):
    global conn
    if (state=='app_state'): return {}
    appstatedict = json.loads(state)
    if 'zoom' not in appstatedict['action']: return {}
    if 'zoomTree' not in appstatedict['action']: return {} # effectively disable the tree for now, it's sooo slow

    G = nx.Graph()

    for h in range(2):  # maxhlevel-minhlevel):
        hlevel = appstatedict['hlevel'] + h
        sql = "select distinct c_fullname AS value,c_name AS label,max(c) c from totalnums t inner join bigfullname b on t.fullname_int=b.fullname_int where c_hlevel='%s' and site='%s' and c_fullname like '%s' group by c_fullname,c_name" % (
            hlevel, appstatedict['site'], '\\'.join(appstatedict['path']) + '\\%')
        items = pd.read_sql_query(sql, conn).to_dict('records')

        for i in items:
            k = i['value']
            c_path = k[:len(k) - 1 - k[:-1][::-1].find("\\")]
            if c_path not in G.nodes.keys():
                G.add_node(c_path,label=c_path,c=0)
            G.add_node(k, label=i['label'], c=i['c'])
            G.add_edge(c_path, k)#, weight=i['c'])

    # Code adapted from https://plot.ly/~empet/14683/networks-with-plotly/#/

    pos = nx.kamada_kawai_layout(G)
    # get coordinates
    Xn = []
    Xe = []
    Nlabel = []
    # for k in pos.keys():
    #    Xn.append(pos[k][0])
    #    Yn.append(pos[k][1])

    Xn = [pos[k][0] for k in pos.keys()]
    Yn = [pos[k][1] for k in pos.keys()]
    Nkeys = [k for k in pos.keys()]
    Nlabel = [G.nodes.data()[k]['label']+'('+str(G.nodes.data()[k]['c'])+')' for k in pos.keys()]
    Nsize = [G.nodes[k]['c'] for k in pos.keys()]
    NsizeMaz = max(Nsize)
    Xe = []
    Ye = []
    for e in G.edges():
        Xe.extend([pos[e[0]][0], pos[e[1]][0], None])
        Ye.extend([pos[e[0]][1], pos[e[1]][1], None])

    # Make it all happen with plotly
    trace_nodes = dict(type='scatter',
                       x=Xn,
                       y=Yn,
                       mode='markers',
                       marker=dict(size=[(k/NsizeMaz)*25 for k in Nsize], color='rgb(0,240,0)'),
                       text=Nlabel,
                       hoverinfo='text')
    trace_edges = dict(type='scatter',
                       mode='lines',
                       x=Xe,
                       y=Ye,
                       line=dict(width=1, color='rgb(25,25,25)'),
                       hoverinfo='none'
                       )

    axis = dict(showline=False,  # hide axis line, grid, ticklabels and  title
                zeroline=False,
                showgrid=False,
                showticklabels=False,
                title=''
                )
    layout = dict(title='Graph of nodes and children',
                  font=dict(family='Balto'),
                  width=1000,
                  height=700,
                  autosize=True,
                  showlegend=False,
                  xaxis=axis,
                  yaxis=axis,
                  margin=dict(
                      l=40,
                      r=40,
                      b=85,
                      t=100,
                      pad=0,

                  ),
                  hovermode='closest',
                  plot_bgcolor='#efecea',  # set background color
                  )

    fig = dict(data=[trace_edges, trace_nodes], layout=layout)
    return fig

if __name__=='__main__':
    initApp("/Users/jklann/Google Drive/SCILHS Phase II/Committee, Cores, Panels/Informatics & Technology Core/totalnums/joined/totalnums.db")
    app.run_server(debug=False)