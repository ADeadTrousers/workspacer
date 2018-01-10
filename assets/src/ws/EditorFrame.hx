package ws;

import js.Browser;
import js.html.*;
import js.jquery.*;
import js.Lib;
import haxe.Template;
import haxe.Json;
import haxe.ds.StringMap;
import symhaxe.html.component.SHApplication;
import symhaxe.html.component.SHComponent;
import Workspacer;
import ws.CodeEditor;

@:expose
@view('ws/EditorFrame.html')
class EditorFrame extends SHComponent
{
    // Variables

    public var dir_path: String;
    public var current_filename: String;
    private var potential_filename: String;
    public var code_editor: CodeEditor;
    var button_set: String;
    var button_sets: StringMap<String>;

    // Lifecycle

    override public function attachedCallback()
    {
        code_editor = SHApplication.createInstance(CodeEditor);
        var settings = Json.parse(new JQuery('#editor-settings').text());
        var value: Dynamic;
        for (name in Reflect.fields(settings)) {
            value = Reflect.field(settings, name);
            if (value != null) {
                code_editor.setAttribute(name, value);
            }
        }
        new JQuery(code_editor).on('save', function (event: Event) {
            new JQuery(this).find('button[accesskey="s"]').trigger('click');
        });
        new JQuery(code_editor).insertAfter(new JQuery(this).find('header'));
        new JQuery(this).on('click', 'button', onButtonClick);
        button_sets = new StringMap<String>();
        button_sets.set('new', translateContent('<button type="button" class="button new float-right" name="create" accesskey="s">{{Create File}}</button>'));
        button_sets.set('edit', translateContent('<button type="button" name="create" class="button edit" style="margin-left: 0">{{Save As}}</button><button type="button" class="button float-right" name="save" style="float: right" accesskey="s">{{Save Changes}}</button>'));
        button_sets.set('edit-xsl', translateContent('<button type="button" class="button edit float-right" name="save" accesskey="s">{{Save Changes}}</button>'));
    }

    // New instance

    public function new()
    {
        super();
    }

    // Accessors

    /*
     * Header text
     */
    public var headerText(never, set): String;

    function set_headerText(text: String): String
    {
        new JQuery(this).find('header p').text(translateContent(text));
        return text;
    }

    // Methods

    /*
     * Open
     */
    public function open(button_set: String): Void
    {
        Browser.window.getSelection().removeAllRanges();
        setButtonSet(button_set);
        code_editor.reset();
        new JQuery('#mask').show();
        this.visible = true;
    }

    /*
     * Close
     */
    public function close(): Void
    {
        this.visible = false;
        new JQuery('#mask').hide();
    }

    function setButtonSet(button_set: String): Void
    {
        this.button_set = button_set;
        this.querySelector('footer').innerHTML = button_sets.get(button_set);
    }

    function getFilePath(filename: String): String
    {
        return (dir_path.length > 0 ? dir_path + "/" : "") + filename;
    }

    /*
     * Edit
     */
    public function edit(?filename: String): Void
    {
        if (filename != null) {
            // Edit existing file.
            potential_filename = filename;
            headerText = '{{Loading}} ${getFilePath(filename)}';
            this.className = "edit";
            code_editor.setText("");
            JQuery.ajax({
                method: 'GET',
                url: Workspacer.ajax_url,
                data: {action: "load", file_path: getFilePath(filename)},
                dataType: 'json'
            })
            .done(function (data) {
                current_filename = potential_filename;
                this.code_editor.setFilename(current_filename);
                this.code_editor.setText(data.text);
                this.headerText = '{{Editing}} ${getFilePath(current_filename)}';
            })
            .fail(function (jqXHR, textStatus: String) {
                this.headerText = '{{Failed to load}} ' + getFilePath(potential_filename);
                Browser.console.log(textStatus);
            });
        } else {
            this.headerText = '{{New File}}';
            this.className = "new";
            this.code_editor.reset();
            this.code_editor.setFilename(null);
        }
    }

    function onButtonClick(event: Event)
    {
        var target = cast(event.target, ButtonElement);
        var file_path;
        switch (target.name) {
        case 'close':
            this.close();

        case 'create':
            var potential_filename: String = Browser.window.prompt(getTranslation('File name'));
            if (potential_filename != null) {
                file_path = Workspacer.filePathFromParts(this.dir_path, potential_filename);
                this.headerText = '{{Creating file}} $file_path';
                Workspacer.S_serverPost(
                    {
                        action: "create",
                        file_path: file_path,
                        text: this.code_editor.getText()
                    },
                    function (data) {
                        if (data.alert_msg == null) {
                            current_filename = potential_filename;
                        }
                        //this.className = "edit";
                        setButtonSet('edit');
                        this.headerText = '{{Editing}} ' + Workspacer.filePathFromParts(this.dir_path, current_filename);
                        this.code_editor.setFilename(current_filename);
                    },
                    function () {
                        this.headerText = current_filename.length > 0
                            ? current_filename : '{{New file}}';
                    }
                );
            }

        case 'save':
            file_path = Workspacer.filePathFromParts(this.dir_path, current_filename);
            this.headerText = '{{Saving}} $file_path';
            //this.code_editor.putFocus();
            Workspacer.S_serverPost(
                {
                    action: "save",
                    file_path: file_path,
                    filename: current_filename,
                    text: this.code_editor.getText()
                },
                function (data: Dynamic) {
                    this.headerText = '{{Editing}} ' + Workspacer.filePathFromParts(this.dir_path, current_filename);
                    code_editor.setFilename(current_filename);
                }
            );
        }
    }

    function getTranslation(key: String): String
    {
        return untyped Symphony.Language.get(key);
        //return LocalizationManager.instance.getString(key);
    }
}