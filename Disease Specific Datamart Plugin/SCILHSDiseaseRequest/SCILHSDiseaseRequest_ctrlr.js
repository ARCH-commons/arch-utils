/**
 * @projectDescription	Example using the Patient Data Object (PDO).
 * @inherits	i2b2
 * @namespace	i2b2.SCILHSDiseaseRequest
 * ----------------------------------------------------------------------------------------
 */

var Dom = YAHOO.util.Dom;
var Event = YAHOO.util.Event;
var DDM = YAHOO.util.DragDropMgr;

//var this.yuiTabs = null;

i2b2.SCILHSDiseaseRequest.showPart2 = function() {
document.getElementById('SCILHSDiseaseRequest-part2a').style.display = '';
document.getElementById('SCILHSDiseaseRequest-part2b').style.display = '';
document.getElementById('SCILHSDiseaseRequest-part2c').style.display = '';
document.getElementById('SCILHSDiseaseRequest-part2d').style.display = '';
i2b2.SCILHSDiseaseRequest.roleRender();
}

i2b2.SCILHSDiseaseRequest.doSubmit = function() {
	
//	this.yuiTabs.set('activeIndex', 1);

this.yuiTabs = new YAHOO.widget.TabView("SCILHSDiseaseRequest-TABS", {activeIndex:1});

this.yuiTabs.set('activeIndex', 1);
//gotoTab(1);
	// recalculate the results only if the input data has changed
	i2b2.SCILHSDiseaseRequest.getResults();
}
//////////////////////////////////////////////////////////////////////////////
// example app
//////////////////////////////////////////////////////////////////////////////
i2b2.SCILHSDiseaseRequest.DDApp = {
    init: function() {

        var rows=3,cols=2,i,j;
        for (i=1;i<cols+1;i=i+1) {
            new YAHOO.util.DDTarget("ul"+i);
        }

        for (i=1;i<cols+1;i=i+1) {
            for (j=1;j<rows+1;j=j+1) {
                new i2b2.SCILHSDiseaseRequest.DDList("li" + i + "_" + j);
            }
        }

        Event.on("showButton", "click", this.showOrder);
        Event.on("switchButton", "click", this.switchStyles);
    },

    showOrder: function() {
        var parseList = function(ul, title) {
            var items = ul.getElementsByTagName("li");
            var out = title + ": ";
            for (i=0;i<items.length;i=i+1) {
                out += items[i].id + " ";
            }
            return out;
        };

        var ul1=Dom.get("ul1"), ul2=Dom.get("ul2");
        alert(parseList(ul1, "List 1") + "\n" + parseList(ul2, "List 2"));

    },

    switchStyles: function() {
        Dom.get("ul1").className = "draglist_alt";
        Dom.get("ul2").className = "draglist_alt";
    }
};

//////////////////////////////////////////////////////////////////////////////
// custom drag and drop implementation
//////////////////////////////////////////////////////////////////////////////

i2b2.SCILHSDiseaseRequest.DDList = function(id, sGroup, config) {

    i2b2.SCILHSDiseaseRequest.DDList.superclass.constructor.call(this, id, sGroup, config);

    this.logger = this.logger || YAHOO;
    var el = this.getDragEl();
    Dom.setStyle(el, "opacity", 0.67); // The proxy is slightly transparent

    this.goingUp = false;
    this.lastY = 0;
};

YAHOO.extend(i2b2.SCILHSDiseaseRequest.DDList, YAHOO.util.DDProxy, {

    startDrag: function(x, y) {
        this.logger.log(this.id + " startDrag");

        // make the proxy look like the source element
        var dragEl = this.getDragEl();
        var clickEl = this.getEl();
        Dom.setStyle(clickEl, "visibility", "hidden");

        dragEl.innerHTML = clickEl.innerHTML;

        Dom.setStyle(dragEl, "color", Dom.getStyle(clickEl, "color"));
        Dom.setStyle(dragEl, "backgroundColor", Dom.getStyle(clickEl, "backgroundColor"));
        Dom.setStyle(dragEl, "border", "2px solid gray");
    },

    endDrag: function(e) {

        var srcEl = this.getEl();
        var proxy = this.getDragEl();

        // Show the proxy element and animate it to the src element's location
        Dom.setStyle(proxy, "visibility", "");
        var a = new YAHOO.util.Motion( 
            proxy, { 
                points: { 
                    to: Dom.getXY(srcEl)
                }
            }, 
            0.2, 
            YAHOO.util.Easing.easeOut 
        )
        var proxyid = proxy.id;
        var thisid = this.id;

        // Hide the proxy and show the source element when finished with the animation
        a.onComplete.subscribe(function() {
                Dom.setStyle(proxyid, "visibility", "hidden");
                Dom.setStyle(thisid, "visibility", "");
            });
        a.animate();
    },

    onDragDrop: function(e, id) {

        // If there is one drop interaction, the li was dropped either on the list,
        // or it was dropped on the current location of the source element.
        if (DDM.interactionInfo.drop.length === 1) {

            // The position of the cursor at the time of the drop (YAHOO.util.Point)
            var pt = DDM.interactionInfo.point; 

            // The region occupied by the source element at the time of the drop
            var region = DDM.interactionInfo.sourceRegion; 

            // Check to see if we are over the source element's location.  We will
            // append to the bottom of the list once we are sure it was a drop in
            // the negative space (the area of the list without any list items)
            if (!region.intersect(pt)) {
                var destEl = Dom.get(id);
                var destDD = DDM.getDDById(id);
                destEl.appendChild(this.getEl());
                destDD.isEmpty = false;
                DDM.refreshCache();
            }

        }
    },

    onDrag: function(e) {

        // Keep track of the direction of the drag for use during onDragOver
        var y = Event.getPageY(e);

        if (y < this.lastY) {
            this.goingUp = true;
        } else if (y > this.lastY) {
            this.goingUp = false;
        }

        this.lastY = y;
    },

    onDragOver: function(e, id) {
    
        var srcEl = this.getEl();
        var destEl = Dom.get(id);

        // We are only concerned with list items, we ignore the dragover
        // notifications for the list.
        if (destEl.nodeName.toLowerCase() == "li") {
            var orig_p = srcEl.parentNode;
            var p = destEl.parentNode;

            if (this.goingUp) {
                p.insertBefore(srcEl, destEl); // insert above
            } else {
                p.insertBefore(srcEl, destEl.nextSibling); // insert below
            }

            DDM.refreshCache();
        }
    }
});


Event.onDOMReady(i2b2.SCILHSDiseaseRequest.DDApp.init, i2b2.SCILHSDiseaseRequest.DDApp, true);

i2b2.SCILHSDiseaseRequest.Init = function(loadedDiv) {
	// register DIV as valid DragDrop target for Patient Record Sets (PRS) objects
	var op_trgt = {dropTarget:true};
	i2b2.sdx.Master.AttachType("SCILHSDiseaseRequest-PRSDROP", "PRS", op_trgt);
	i2b2.sdx.Master.AttachType("SCILHSDiseaseRequest-EXCPRSDROP", "PRS", op_trgt);

	// drop event handlers used by this plugin
	i2b2.sdx.Master.setHandlerCustom("SCILHSDiseaseRequest-PRSDROP", "PRS", "DropHandler", i2b2.SCILHSDiseaseRequest.prsDropped);
	i2b2.sdx.Master.setHandlerCustom("SCILHSDiseaseRequest-EXCPRSDROP", "PRS", "DropHandler", i2b2.SCILHSDiseaseRequest.excprsDropped);

	// set default output options
	i2b2.SCILHSDiseaseRequest.model.outputOptions = {};
	i2b2.SCILHSDiseaseRequest.model.outputOptions.patients = true;
	i2b2.SCILHSDiseaseRequest.model.outputOptions.events = true;
	i2b2.SCILHSDiseaseRequest.model.outputOptions.observations = true;

	// array to store patient sets
	i2b2.SCILHSDiseaseRequest.model.prs = [];
	i2b2.SCILHSDiseaseRequest.model.excprs = [];

	// Create all the roles needed
	//i2b2.SCILHSDiseaseRequest.roleRender();
	

	// manage YUI tabs
	this.yuiTabs = new YAHOO.widget.TabView("SCILHSDiseaseRequest-TABS", {activeIndex:0});
	/*
	this.yuiTabs.on('activeTabChange', function(ev) { 
		//Tabs have changed 
		if (ev.newValue.get('id')=="SCILHSDiseaseRequest-TAB1") {
			// user switched to Results tab
			//if (i2b2.SCILHSDiseaseRequest.model.conceptRecord && i2b2.SCILHSDiseaseRequest.model.prsRecord && i2b2.SCILHSDiseaseRequest.model.excconceptRecord && i2b2.SCILHSDiseaseRequest.model.excprsRecord && i2b2.SCILHSDiseaseRequest.model.icRecord && i2b2.SCILHSDiseaseRequest.model.excicRecord) {
			// contact PDO only if we have data
		//	if (i2b2.SCILHSDiseaseRequest.model.dirtyResultsData) {
					// recalculate the results only if the input data has changed
					i2b2.SCILHSDiseaseRequest.getResults();
			//	}
		//	}
		}
	});
	*/
		z = $('anaPluginViewFrame').getHeight() - 34;
	$$('DIV#SCILHSDiseaseRequest-TABS DIV.SCILHSDiseaseRequest-MainContent')[0].style.height = z;
	$$('DIV#SCILHSDiseaseRequest-TABS DIV.SCILHSDiseaseRequest-MainContent')[1].style.height = z;
	$$('DIV#SCILHSDiseaseRequest-TABS DIV.SCILHSDiseaseRequest-MainContent')[2].style.height = z;


};

i2b2.SCILHSDiseaseRequest.Unload = function() {
	// purge old data
	i2b2.SCILHSDiseaseRequest.model.prsRecord = false;
	i2b2.SCILHSDiseaseRequest.model.excprsRecord = false;
	i2b2.SCILHSDiseaseRequest.model.dirtyResultsData = true;
	i2b2.SCILHSDiseaseRequest.model.outputOptions.patients = true;
	i2b2.SCILHSDiseaseRequest.model.outputOptions.events = true;
	i2b2.SCILHSDiseaseRequest.model.outputOptions.observations = true;
	return true;
};

i2b2.SCILHSDiseaseRequest.prsDropped = function(sdxData) {
	sdxData = sdxData[0];	// only interested in first record
		// save the info to our local data model
	i2b2.SCILHSDiseaseRequest.model.prs.push(sdxData);
	// sort and display the concept list
	i2b2.SCILHSDiseaseRequest.prsRender();
	// optimization to prevent requerying the hive for new results if the input dataset has not changed
	i2b2.SCILHSDiseaseRequest.model.dirtyResultsData = true;		
};

i2b2.SCILHSDiseaseRequest.excprsDropped = function(sdxData) {
	sdxData = sdxData[0];	// only interested in first record
		// save the info to our local data model
	i2b2.SCILHSDiseaseRequest.model.excprs.push(sdxData);
	// sort and display the concept list
	i2b2.SCILHSDiseaseRequest.excprsRender();
	// optimization to prevent requerying the hive for new results if the input dataset has not changed
	i2b2.SCILHSDiseaseRequest.model.dirtyResultsData = true;		
};


i2b2.SCILHSDiseaseRequest.prsDelete = function(prsIndex) {
	// remove the selected patient set
	i2b2.SCILHSDiseaseRequest.model.prs.splice(prsIndex,1);
	// sort and display the patient set list
	i2b2.SCILHSDiseaseRequest.prsRender();
	// optimization to prevent requerying the hive for new results if the input dataset has not changed
	i2b2.SCILHSDiseaseRequest.model.dirtyResultsData = true;		
};

i2b2.SCILHSDiseaseRequest.excprsDelete = function(excprsIndex) {
	// remove the selected patient set
	i2b2.SCILHSDiseaseRequest.model.excprs.splice(excprsIndex,1);
	// sort and display the patient set list
	i2b2.SCILHSDiseaseRequest.excprsRender();
	// optimization to prevent requerying the hive for new results if the input dataset has not changed
	i2b2.SCILHSDiseaseRequest.model.dirtyResultsData = true;		
};



i2b2.SCILHSDiseaseRequest.chgOutputOption = function(ckBox,option) {
	i2b2.SCILHSDiseaseRequest.model.outputOptions[option] = ckBox.checked;
	i2b2.SCILHSDiseaseRequest.model.dirtyResultsData = true;
};



i2b2.SCILHSDiseaseRequest.addTopic = function() {
	 
	// Get the roles
	var proj_data = i2b2.PM.view.admin.currentProject;
	
	var recList = i2b2.PM.ajax.getApproval("PM:Admin", {});
	// custom parse functionality
	
	
	recList.parse();
	var tmp = {};
	var l = recList.model.length;
	for (var i=0; i<l; i++) {
			var id = recList.model[i].id;
			var name = recList.model[i].name;
			var description = recList.model[i].description;
			
			var select = document.getElementById("SCILHSDiseaseRequest-OutputApproval");
			select.options[select.options.length] = new Option(name + " - " + description, id);
	}
	delete recList;

};

i2b2.SCILHSDiseaseRequest.roleRender = function() {
	var s = '<table width="100%"><tr><td>User</td><td>Data Role</td><td>Admin Role</td></tr>';
 
	// Get the roles
	var proj_data = i2b2.PM.view.admin.currentProject;
	
	//var recList = i2b2.PM.ajax.getAllParam("PM:Admin", {id: "ra_mart_test", proj_path:"/"});
	
	
	//User Params
	var recList = i2b2.PM.ajax.getAllParam("PM:Admin", {table:"user", id_xml:"<param name='APPROVAL_ID'>"+ document.getElementById("SCILHSDiseaseRequest-OutputApproval").value +"</param>"});
	// custom parse functionality
	var tmp = [];
	var c = i2b2.h.XPath(recList.refXML, "//user[user_name and param]");
	var l = c.length;
	for (var i=0; i<l; i++) {
		try {
			//var tmpRec = {};
			//tmpRec.name = i2b2.h.XPath(c[i], "attribute::name")[0].nodeValue;
			//tmpRec.id = i2b2.h.XPath(c[i], "attribute::id")[0].nodeValue;
			//tmpRec.datatype = i2b2.h.XPath(c[i], "attribute::datatype")[0].nodeValue;
			//tmpRec.value = i2b2.h.XPath(c[i], "text()")[0].nodeValue;
			var username = i2b2.h.XPath(c[i], "descendant-or-self::user/user_name/text()")[0].nodeValue;

			//tmp.push(tmpRec);
			i2b2.SCILHSDiseaseRequest.model.users.push(username);

			
			s += '<tr><td>' + username + '</td>';
			s += '<td> <select id="SCILHSDiseaseRequest-UserDataRole-'+ username +'"><option>None</option><option name="DATA_PROT">DATA_PROT</option><option name="DATA_DEID">DATA_DEID</option><option name="DATA_LDS">DATA_LDS</option><option name="DATA_AGG">DATA_AGG</option><option name="DATA_OBFSC">DATA_OBFSC</option></select></td><td> <select id="SCILHSDiseaseRequest-UserAdminRole-'+ username +'"><option>None</option><option name="ADMIN">ADMIN</option><option name="MANAGER">MANAGER</option><option name="EDITOR">EDITOR</option><option name="USER">USER</option></select></td></tr>';
	
		} catch(e) {}
	}

	
	//Project-User param
		var recList = i2b2.PM.ajax.getAllParam("PM:Admin", {table:"project_user", param_xml:' id="'+i2b2.PM.model.login_project+'"', id_xml:"<param name='APPROVAL_ID'>"+ document.getElementById("SCILHSDiseaseRequest-OutputApproval").value +"</param>"});
	// custom parse functionality
	var tmp = [];
	var c = i2b2.h.XPath(recList.refXML, "//user[user_name and param]");
	var l = c.length;
	for (var i=0; i<l; i++) {
		try {
			//var tmpRec = {};
			//tmpRec.name = i2b2.h.XPath(c[i], "attribute::name")[0].nodeValue;
			//tmpRec.id = i2b2.h.XPath(c[i], "attribute::id")[0].nodeValue;
			//tmpRec.datatype = i2b2.h.XPath(c[i], "attribute::datatype")[0].nodeValue;
			//tmpRec.value = i2b2.h.XPath(c[i], "text()")[0].nodeValue;
			var username = i2b2.h.XPath(c[i], "descendant-or-self::user/user_name/text()")[0].nodeValue;

			//tmp.push(tmpRec);
			
			
			s += '<tr><td>' + username + '</td>';
			s += '<td> <select id="SCILHSDiseaseRequest-OuputApproval-'+ username +'"><option>None</option><option name="DATA_PROT">DATA_PROT</option><option name="DATA_DEID">DATA_DEID</option><option name="DATA_LDS">DATA_LDS</option><option name="DATA_AGG">DATA_AGG</option><option name="DATA_OBFSC">DATA_OBFSC</option></select></td><td> <select id="SCILHSDiseaseRequest-OuputApproval"><option>None</option><option name="ADMIN">ADMIN</option><option name="MANAGER">MANAGER</option><option name="EDITOR">EDITOR</option><option name="USER">USER</option></select></td></tr>';
	
		} catch(e) {}
	}

	
	
	// custom parse functionality
	/*
	var tmpRoles = {};
	var c = i2b2.h.XPath(recList.refXML, "//role[user_name and role]");
	var l = c.length;
	for (var i=0; i<l; i++) {
		try {
			var name = i2b2.h.XPath(c[i], "descendant-or-self::role/user_name/text()")[0].nodeValue;
			if (!tmpRoles[name]) {
				
				
				tmpRoles[name] = [];
		s += '<tr><td>' + name + '</td>';
		s += '<td> <select id="SCILHSDiseaseRequest-OuputApproval"><option>None</option><option name="DATA-DEID">DATA_DEID</option><option name="DATA_AGG">DATA_AGG</option><option name="">DATA_LDS</option><option name="DATA_OBFSC">DATA_OBFSC</option></select></td><td> <select id="SCILHSDiseaseRequest-OuputApproval"><option>None</option><option name="ADMIN">ADMIN</option><option name="MANAGER">MANAGER</option><option name="EDITOR">EDITOR</option><option name="USER">USER</option></select></td></tr>';
				
			}
			tmpRoles[name].push(i2b2.h.XPath(c[i], "descendant-or-self::role/role/text()")[0].nodeValue);
		} catch(e) {}
	}
	*/
	s += '</table>';
	// update html
	$("SCILHSDiseaseRequest-roleItem").innerHTML = s;
};

i2b2.SCILHSDiseaseRequest.prsRender = function() {
	var s = '';
	// are there any patient set in the list
	if (i2b2.SCILHSDiseaseRequest.model.prs.length) {
		// sort the concepts in alphabetical order
		i2b2.SCILHSDiseaseRequest.model.prs.sort(function() {return arguments[0].sdxInfo.sdxDisplayName > arguments[1].sdxInfo.sdxDisplayName});
		// draw the list of patient set
		for (var i1 = 0; i1 < i2b2.SCILHSDiseaseRequest.model.prs.length; i1++) {
			if (i1 > 0) { s += '<div class="prsDiv"></div>'; }
			s += '<a class="prsItem" href="JavaScript:i2b2.SCILHSDiseaseRequest.prsDelete('+i1+');">' + i2b2.h.Escape(i2b2.SCILHSDiseaseRequest.model.prs[i1].sdxInfo.sdxDisplayName) + '</a>';
		}
		// show the delete message
		$("SCILHSDiseaseRequest-DeleteMsgPRS").style.display = 'block';
	} else {
		// no patient set selected yet
		s = '<div class="prsItem">Drop one or more Patient Set here</div>';
		$("SCILHSDiseaseRequest-DeleteMsgPRS").style.display = 'none';
	}
	// update html
	$("SCILHSDiseaseRequest-PRSDROP").innerHTML = s;
};

i2b2.SCILHSDiseaseRequest.excprsRender = function() {
	var s = '';
	// are there any patient set in the list
	if (i2b2.SCILHSDiseaseRequest.model.excprs.length) {
		// sort the concepts in alphabetical order
		i2b2.SCILHSDiseaseRequest.model.excprs.sort(function() {return arguments[0].sdxInfo.sdxDisplayName > arguments[1].sdxInfo.sdxDisplayName});
		// draw the list of patient set
		for (var i1 = 0; i1 < i2b2.SCILHSDiseaseRequest.model.excprs.length; i1++) {
			if (i1 > 0) { s += '<div class="excprsDiv"></div>'; }
			s += '<a class="excprsItem" href="JavaScript:i2b2.SCILHSDiseaseRequest.excprsDelete('+i1+');">' + i2b2.h.Escape(i2b2.SCILHSDiseaseRequest.model.excprs[i1].sdxInfo.sdxDisplayName) + '</a>';
		}
		// show the delete message
		$("SCILHSDiseaseRequest-DeleteMsgExcPRS").style.display = 'block';
	} else {
		// no patient set selected yet
		s = '<div class="excprsItem">Drop one or more Patient Set here</div>';
		$("SCILHSDiseaseRequest-DeleteMsgExcPRS").style.display = 'none';
	}
	// update html
	$("SCILHSDiseaseRequest-EXCPRSDROP").innerHTML = s;
};


i2b2.SCILHSDiseaseRequest.icRender = function() {
	var s = '';
	// are there any patient set in the list
	if (i2b2.SCILHSDiseaseRequest.model.ic.length) {
		// sort the concepts in alphabetical order
		i2b2.SCILHSDiseaseRequest.model.ic.sort(function() {return arguments[0].sdxInfo.sdxDisplayName > arguments[1].sdxInfo.sdxDisplayName});
		// draw the list of patient set
		for (var i1 = 0; i1 < i2b2.SCILHSDiseaseRequest.model.ic.length; i1++) {
			if (i1 > 0) { s += '<div class="icDiv"></div>'; }
			s += '<a class="prsItem" href="JavaScript:i2b2.SCILHSDiseaseRequest.icDelete('+i1+');">' + i2b2.h.Escape(i2b2.SCILHSDiseaseRequest.model.ic[i1].sdxInfo.sdxDisplayName) + '</a>';
		}
		// show the delete message
		$("SCILHSDiseaseRequest-DeleteMsgIC").style.display = 'block';
	} else {
		// no patient set selected yet
		s = '<div class="icItem">Drop one or more Patient Set here</div>';
		$("SCILHSDiseaseRequest-DeleteMsgIC").style.display = 'none';
	}
	// update html
	$("SCILHSDiseaseRequest-ICDROP").innerHTML = s;
};

i2b2.SCILHSDiseaseRequest.excicRender = function() {
	var s = '';
	// are there any patient set in the list
	if (i2b2.SCILHSDiseaseRequest.model.excic.length) {
		// sort the concepts in alphabetical order
		i2b2.SCILHSDiseaseRequest.model.excic.sort(function() {return arguments[0].sdxInfo.sdxDisplayName > arguments[1].sdxInfo.sdxDisplayName});
		// draw the list of patient set
		for (var i1 = 0; i1 < i2b2.SCILHSDiseaseRequest.model.excic.length; i1++) {
			if (i1 > 0) { s += '<div class="excicDiv"></div>'; }
			s += '<a class="excprsItem" href="JavaScript:i2b2.SCILHSDiseaseRequest.excicDelete('+i1+');">' + i2b2.h.Escape(i2b2.SCILHSDiseaseRequest.model.excic[i1].sdxInfo.sdxDisplayName) + '</a>';
		}
		// show the delete message
		$("SCILHSDiseaseRequest-DeleteMsgExcIC").style.display = 'block';
	} else {
		// no patient set selected yet
		s = '<div class="excicItem">Drop one or more Patient Set here</div>';
		$("SCILHSDiseaseRequest-DeleteMsgExcIC").style.display = 'none';
	}
	// update html
	$("SCILHSDiseaseRequest-EXCICDROP").innerHTML = s;
};

i2b2.SCILHSDiseaseRequest.getResults = function() {


		var url = 'js-i2b2/cells/plugins/standard/SCILHSDiseaseRequest/assets/' +  document.getElementById("SCILHSDiseaseRequest-dbvendor").value + '.sql';
//i2b2[pluginCode].cfg.config.assetDir + i2b2[pluginCode].cfg.config.plugin.html.source;
			var response = new Ajax.Request(url, {method: 'get', asynchronous: false});
			console.dir(response);
			if (response.transport.statusText=="OK") {
				var doc = response.transport.responseText;
				if (i2b2.SCILHSDiseaseRequest.model.prs.length)
				{
					doc = doc.replace("{$1}", i2b2.SCILHSDiseaseRequest.model.prs[0].sdxInfo.sdxKeyValue);
				} else {
					 doc = doc.replace("{$1}", "null");
				}
                               if (i2b2.SCILHSDiseaseRequest.model.excprs.length)
                                {
                                        doc = doc.replace("{$2}", i2b2.SCILHSDiseaseRequest.model.excprs[0].sdxInfo.sdxKeyValue);
                                } else {
                                         doc = doc.replace("{$2}", "null");
                                }
                                doc = doc.replace("{$0}",  document.getElementById("SCILHSDiseaseRequest-title").value);
				doc = doc.replace(/_CRCDB_/g,  document.getElementById("SCILHSDiseaseRequest-crcdb").value);
				doc = doc.replace(/_ONTDB_/g,  document.getElementById("SCILHSDiseaseRequest-ontdb").value);
				var trgt = $('sqlcreatedm');
				trgt.innerHTML = "<textarea  onClick=\"this.focus(); this.select();\" readonly  style=\"width: 492px; height: 211px;\">" + doc + "</textarea>";

				// load the html into the IFRAME
				/*
				var doc = $('anaPluginIFRAME').contentDocument;
				if (!doc) {var doc = $('anaPluginIFRAME').contentWindow.document; }
				doc.open();
				doc.write(response.transport.responseText);
				doc.close();
				// get the main screen DIV
				var mainDiv = doc.getElementById(i2b2[pluginCode].cfg.config.plugin.html.mainDivId);
				if (!mainDiv) {
				alert("The Plugin's screen was loaded but had errors.");
				return false;
				}
				*/
			}	

		$$("DIV#SCILHSDiseaseRequest-mainDiv DIV#SCILHSDiseaseRequest-TABS DIV.results-directions")[0].hide();
		$$("DIV#SCILHSDiseaseRequest-mainDiv DIV#SCILHSDiseaseRequest-TABS DIV.results-finished")[0].show();
		$$("DIV#SCILHSDiseaseRequest-mainDiv DIV#SCILHSDiseaseRequest-TABS DIV.results-working")[0].hide();		
	};
