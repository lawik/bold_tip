var editors = document.getElementsByClassName("boldtip-richtext-editor")

var editorArea = document.getElementsByClassName("editor")[0];
var editorElement = document.getElementById("editor");
var editorTargetElement = document.getElementById("target-editor");
var schemaElement = document.getElementById("metadata-schema");
var metadataElement = document.getElementById("metadata-editor");
var metadataTargetElement = document.getElementById("target-metadata");

if (editors.length > 0) {
    var toolbar_options =   [
        [{ 'header': [1, 2, 3, 4, 5, 6, false] }],
        ['bold', 'italic', 'underline'],        // toggled buttons
        [{ 'list': 'ordered'}, { 'list': 'bullet' }],
        
        ['image', 'link', 'video'],
        
        ['blockquote', 'code-block'],
        
        [{ 'direction': 'rtl' }],                         // text direction
        
        ['clean']                                         // remove formatting button
    ];
    Array.prototype.forEach.call(editors, function (editorElement) {
        var editorElementId = editorElement.getAttribute("id");
        var targetId = editorElement.getAttribute("data-target");
        var editorTargetElement = document.getElementById(targetId);
        editorTargetElement.form.classList.add("use-visual-editor");
        editorTargetElement.form.classList.add("has-editor");

        var editor = new Quill('#' + editorElementId, {
            modules: {
                toolbar: toolbar_options,
                keyboard: {
                    bindings: {
                        tab: {
                            key: 9,
                            handler: function () {
                                return true;
                            }
                        }
                    }
                }
            },
            theme: 'snow'
        });

        /*
        Progressive enhancement. The dumb basic version is editing HTML in a textarea. But it works without JS.
        With JS, hide that. Use Quill.js.
        On user editing in Quill.js, update the textarea.
        */
        editor.on('text-change', function (delta, oldDelta, source) {
            if (source == 'user') {
                var content = editor.root.innerHTML;
                editorTargetElement.value = content;
            }
         });

         editorTargetElement.form.addEventListener("submit", function () {
            if (editorElement !== null && editor) {
                var editorContent = editor.root.innerHTML;
                editorTargetElement.value = editorContent;
            }
        
            if (metadataElement !== null && metadata) {
                var data = JSON.stringify(metadata.getValue());
                var metadataContent = data;
            }
         });
    });
}
