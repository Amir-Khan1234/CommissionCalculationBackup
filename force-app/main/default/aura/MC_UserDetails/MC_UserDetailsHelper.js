({
    populateCommissionMasterSchema : function(component, event, helper){
        //debugger; 
        component.set("v.showSpinner",true);
        var action = component.get("c.getCommissionStructureByUserId");
        action.setParams({ 
            userProfileName : component.get("v.currentLoggedInUser").Profile.Name
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            component.set("v.showSpinner",false);
            debugger;
            if (state === "SUCCESS") {
                console.log("currentLoggedInUser"+ component.get("v.currentLoggedInUser"));
                console.log("commissionStructure"+JSON.stringify(response.getReturnValue()));
                component.set("v.commissionStructure",response.getReturnValue());
            }
            else if (state === "INCOMPLETE") {
                // do something
            }
                else if (state === "ERROR") {
                    var errors = response.getError();
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log("Error message: " + 
                                        errors[0].message);
                            let errorObj = {'className' : "MC_UserDetails - Aura"};
                            if(errors[0].message.includes('Trace')){                            
                                let err = errors[0].message.split('Trace');
                                errorObj.apexTrace= err[1];
                                errorObj.exceptionMsg = err[0]
                            }
                            else{
                                errorObj.apexTrace= 'helper.populateCommissionMaster';
                                errorObj.exceptionMsg = errors[0].message;
                            }
                            helper.CreateExceptionLog(component,event,helper,errorObj);
                        }
                    } else {
                        console.log("Unknown error");
                    }
                }
        });
        $A.enqueueAction(action);
    }
})