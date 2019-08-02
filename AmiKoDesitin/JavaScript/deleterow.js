
function deleteRow(msg,tableID,currentRow) {
    // var myfunc = window.RemoveMeds;
    try {
        if (msg=="Notify_interaction") {
            WebViewJavascriptBridge.send("notify_interaction");
        } else if (msg=="Delete_all") {
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
            WebViewJavascriptBridge.send("delete_all");
		} else {
            //
            // window.alert("delete single row");
            //
            var table = document.getElementById(tableID);
			var rowCount = table.rows.length;
            for (var i=0; i<rowCount; i++) {
				var row = table.rows[i];
				if (row==currentRow.parentNode.parentNode) {
                    // Notify objc
                    WebViewJavascriptBridge.send(row.cells[1].innerText);
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
