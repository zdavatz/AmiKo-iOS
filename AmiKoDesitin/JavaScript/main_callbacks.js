function displayFachinfo(ean, anchor) {
    var messageToPost = {'EanCode':ean, 'Anchor':anchor};
    window.webkit.messageHandlers.buttonClicked.postMessage(messageToPost);
}
