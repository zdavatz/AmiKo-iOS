function displayFachinfo(ean, anchor) {
    var messageToPost = {'EanCode':ean, 'Anchor':anchor};
    window.webkit.messageHandlers.buttonClicked.postMessage(messageToPost);
}

function moveToHighlight(anchor) {
    if (typeof anchor !== 'undefined') {
        try {
            var elem = document.getElementById(anchor);
            if (elem !== null) {
                var marks = elem.getElementsByClassName('mark')
                if (marks.length > 0) {
                    marks[0].scrollIntoView(true);
                }
            }
        } catch(e) {
            alert(e);
        }
    }
}

function highlightText(node, text) {
    if (node instanceof Text) {
        var splitted = node.data.split(text);
        if (splitted.length === 1) {
            // Not found, no replace
            return null;
        }
        // Create a new element with text highlighted
        var wrapper = document.createElement('span');
        for (var i = 0; i < splitted.length; i++) {
            var thisText = document.createTextNode(splitted[i]);
            wrapper.appendChild(thisText);
            if (i !== splitted.length - 1) {
                var thisSpan = document.createElement('span');
                thisSpan.innerText = text;
                thisSpan.style.backgroundColor = getComputedStyle(document.documentElement).getPropertyValue('--text-color-highlight');
                thisSpan.className = 'mark';
                wrapper.appendChild(thisSpan);
            }
        }
        return wrapper;
    }
    var nodeName = node.nodeName.toLowerCase();
    if (nodeName === 'script' || nodeName === 'style') {
        return null;
    }
    var nodes = node.childNodes;
    for (var i = 0; i < nodes.length; i++) {
        var thisNode = nodes[i];
        var newNode = highlightText(thisNode, text);
        if (newNode !== null) {
            node.replaceChild(newNode, thisNode);
        }
    }
    return null;
}

