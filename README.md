# postalservice-example
this is a simple example of postal javascript how subscribe and publish works

**### Teamcenter Active workspace example secanrio**
Steps to test this:


1. Install Node
2. npm init -y
3. npm install postal
4. node postal-example.js


**The same concept is used for Active workspace.**

**sample prototype:**

Here is one use case of it:
To understand this basics come from postal-example.js
This prototype demonstrates the message publishing and subscription behaviour inside Active workspace as a simple example.

Prototype

Lets take an  abstract usecase:
Update attribute 1 if attribute 2 is updated. Attribute 1 is on item revision and attribute 2 is on the revision master form as an example.

Lets take a clean example: 
As we know we have some ootb revision master form attributes. lets try to map and build a usecase scenario.
User_data_1 = should be mapped to object_name of item revision
User_data_2 = should be mapped to object_desc of item revision.



We can subscribe to the events that are produced during an eevent, and do some extended behaviour of Active workspace.

For example:
Create
Edit, there could be events like: cdm.new is for create new event
and cdm.updated is for update of some thing existing event

node_modules\@swf\core\src\declarativeui\src\js\eventBus.js

Here there is a function called publish.
You can add debug statement here like inside publish function
Add a call like

debugService.debug( 'globalEvents', topic );
debugService.debug( 'eventData', eventData);

Or 
console.log(topic, eventData);

Sample:
export let publish = function( topic, eventData, isCustomEvent ) {
    debugService.debug( 'globalEvents', topic );
    console.log(topic, eventData);
    var doLogging = false;


….

To understand what types of events appear during actions in active workspace.

Now we come back to subscribe function, here we can add a one liner like below:


import CustomEventSubscriptionfrom 'js/CustomEventSubscription';

export let subscribe = function( topic, callbackFn, subId ) {
    CustomEventSubscription.addSubscriptions()
    var subDef = postal.subscribe( {
        channel: 'soajs',
        topic: topic,
        callback: callbackFn
    } );


Now create a module by name CustomEventSubscriptions

A file by name CustomEventSubscriptions/src/js/CustomEventSubscriptions.js

import eventBus from "js/eventBus"
import MyFirstEventSubscriptions from "js/MyFirstEventSubscriptions";

let exports ={}

Let isCustomSubscriptionsAdded = false;

Exports.addSubscriptions = function() {
If(!Boolean(isCustomSubscriptionsAdded )) {
	isCustomSubscriptionsAdded = true;
	
	eventBus.subscribe("cdm.updated", safewrapper(MyFirstEventSubscriptions.cdm_updated)); 
	eventBus.subscribe("tcDataprovider.validSelectionEvent", safewrapper(MyFirstEventSubscriptions.tcDataprovider_validSelectionEvent));
	eventBus.subscribe("cdm.new", safewrapper(MyFirstEventSubscriptions.cdm_new));

/* why this safe wrapper?!!
Explaination: when consuming the OOTB events, if your function throws error, then it would disrupt the flow of whole AWC.

Assume you have a function registered for authentication.complete event, and assume authentication.complete event gets triggered every time a user reloads the page, and If your function is throwing an error, then AWC would never load, it would be stopped in the authentication.complete event itself. 

Thats why we have made safeWrapper. This would catche any error safely before reaching the OOTB code which triggered the event :)) it is like destroying the error here itself and not to propagate or inform the caller.

You can also catch the error in your function itself and show it using messageService but for simplicity we do this way..
*/


let safeWrapper = function (callback) {
	return function (eventData) {
		try {
			callback(eventData);
		} catch (error) {
			console.error("Error in a custom Event:");
			console.error(error);
		}
	};
};

export default exports;


---
A file by name CustomEventSubscriptions/src/js/MyFirstEventSubscriptions.js

// Here we need to be little careful as importing some thing without knowledge may cause an atomic chain reaction and // the how eventBus concept may collapse. Only import the basic stuff, and import per function if required additionally // required imports. See this example: we imported import("soa/dataManagementService") on pro-rata or need basis.

import eventBus from "js/eventBus";
//import soaService from "soa/kernel/soaService"; => Dont do this ! The entire active workspace eco system will collapse.
import _ from "lodash";

let exports = {};

// cdm_updated event basis
exports.cdm_updated = function (eventData) {
	//check if updatedObjects is not empty
	if (_.has(eventData, "updatedObjects[0]")) {
		let changes = getUserDataChange(eventData.updatedObjects);
		if (changes.length > 0) {
			setProperties(changes);
		}
	}
};

//cdm_new event basis
exports.cdm_new = function (eventData) {
	//check if addedObjects is not empty
	if (_.has(eventData, "newObjects[0]")) {
		let changes = getUserDataChange(eventData.newObjects);
		if (changes.length > 0) {
			setProperties(changes);
		}
	}
};

let getUserDataChange= function (objList) {
	let changes = [];

	objList.forEach((modelObj) => {
		if (modelObj.type === "Item Revision") {
			getRevChangesToModify(modelObj, changes);
		}
	});

	return changes;
};

let getRevChangesToModify = function (revObj, changes) {
	let arr = [];

	let object_name = _.result(revObj, "props.object_name.dbValues[0]");
	let object_desc = _.result(revObj, "props.object_desc.dbValues[0]");
	let user_data_1 = _.result(revObj, "props.user_data_1.dbValues[0]");
	let user_data_2 = _.result(revObj, "props.user_data_2.dbValues[0]");

	if (Boolean(user_data_1)) {
		if (object_name !== user_data_1) {
			arr.push({
				name: "object_name",
				values: [user_data_1],
			});
		}
	}
	if (Boolean(user_data_2)) {
		if (object_desc !== user_data_2) {
			arr.push({
				name: "object_desc",
				values: [user_data_2],
			});
		}
	}
	if (arr.length > 0) {
		changes.push({
			object: revObj,
			vecNameVal: arr,
		});
	}
};

let setProperties = function (changes) {
	import("soa/dataManagementService").then(function (dmService) {
		dmService.setProperties(changes).then(
			function (response) {
				console.log("Item Revision property set successfully. ", changes);
			},
			function (err) {
				console.log("Item Revision property set failed !!.", err);
			}
		);
	});
};

exports.tcDataprovider_validSelectionEvent = function (eventData) {
	/* to investigate in future
	
	*/
	-- This is not implemented
};

export default exports;
![image](https://github.com/bharathulaprasad/postalservice-example/assets/76819369/4b3e90b0-2ce3-410d-b883-6d4fd6405785)


