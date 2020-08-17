//TODO: - 待处理
var console = {};
console.log = function(message){
    window.webkit.messageHandlers['Native'].postMessage(message)
};

//setTimeout(function(){
//    console.log(document.documentElement.scrollWidth)
//
//}, 0)


