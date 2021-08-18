window.onload = function() {
//  alert("Warning!");
};

// --------------------------------------------------------
// Tree
// --------------------------------------------------------
/* main */
function insert_json_tree(id,indata){
    var div=document.createElement('div');
    var li=document.createElement('li');
    li.innerHTML=id;
    li.classList.add("node_close");
    div.addEventListener("click",{handleEvent: click_tree});
    div.appendChild(li);
    recurse_json(div,indata);
    div.id = id + "_tree";
    document.getElementById(id).appendChild(div);
};

/* クリック動作 */
function click_tree(mouse_event){
    mouse_event.stopPropagation();
    var element =mouse_event.currentTarget;
    var hoge = element.children;
    for(var i = 0; i < hoge.length; i++){
        if (i < 1){
            if(hoge[i].className == "node_open"){
                hoge[i].className = "node_close";
            }
            else{
                hoge[i].className = "node_open";
            }
        }
        else{
            if(hoge[i].style.display == "none"){
                hoge[i].style.display = "block";
            }
            else{
                hoge[i].style.display = "none";
            }
        }
    }
};

/* 再帰 */
function recurse_json(element,indata){
    if (indata instanceof Array) {
        //[]
        indata.forEach(function(item){
            recurse_json(element,item) ;
        });
    }
    else if(typeof indata == "object"){
        //{}
        var sub=document.createElement('ul');
        sub.style.display = "none";
        element.appendChild(sub);
        for (var key in indata){
            var node=document.createElement('div');
            var li=document.createElement('li');
            li.classList.add("node_close");
            li.innerHTML=key;
            node.addEventListener("click",{handleEvent: click_tree});
            node.appendChild(li);
            sub.appendChild(node);
            recurse_json(node,indata[key]) ;
        }
    }
    else {
        var content=document.createElement('ul');
        content.style.display = "none";
        content.innerHTML=indata;
        element.appendChild(content);
    }
}
