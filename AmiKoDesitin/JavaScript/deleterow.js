
function deleteRow(msg,tableID,currentRow) {
    // var myfunc = window.RemoveMeds;
    try {
        if (msg=="Notify_interaction") {
            WebViewJavascriptBridge.callHandler("JSToObjC_",
                                                "notify_interaction",
                                                function responseCallback(responseData) {
                                                    console.log("JS received response:", responseData);
                                                });
        }
        else if (msg=="Delete_all") {
            //
            // window.alert("delete all rows");
            //
            // Remove all rows
            var table = document.getElementById(tableID);
            var rowCount = table.rows.length;
            for (var i=rowCount; i>0; i--) {
                table.deleteRow(i-1);
            }
            // Notify objc
            WebViewJavascriptBridge.callHandler("JSToObjC_",
                                                "delete_all",
                                                function responseCallback(responseData) {
                                                    console.log("JS received response:", responseData);
                                                });
		}
        else {
            //
            // window.alert("delete single row");
            //
            var table = document.getElementById(tableID);
			var rowCount = table.rows.length;
            for (var i=0; i<rowCount; i++) {
				var row = table.rows[i];
				if (row==currentRow.parentNode.parentNode) {
                    // Notify objc
                    WebViewJavascriptBridge.callHandler("JSToObjC_",
                                                        row.cells[1].innerText,
                                                        function responseCallback(responseData) {
                                                            console.log("JS received response:", responseData);
                                                        });

					// Delete row
					table.deleteRow(i);		
					// Update counters
					rowCount--;
				}
			}
        }
    } catch (e) {
        window.alert(e);
    }
}
