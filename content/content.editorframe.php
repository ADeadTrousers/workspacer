<?php

require_once TOOLKIT . '/class.administrationpage.php';
require_once EXTENSIONS . '/workspacer/lib/class.path_object.php';

use workspacer\Helpers as Helpers;
use workspacer\PathObject as PathObject;

class contentExtensionWorkspacerEditorframe extends HTMLPage
{
    const ID = 'workspacer';
    static $assets_base_url;
    //public $content_base_url;
    //public $_existing_file;

    public function __construct()
    {
        self::$assets_base_url = URL . '/extensions/workspacer/assets/';
        parent::__construct();
        $this->settings = (object)Symphony::Configuration()->get(self::ID);
    }

    public function build(array $context = array())
    {
        $this->_context = $context;

        /*if (!$this->canAccessPage()) {
            Administration::instance()->throwCustomError(
                __('You are not authorised to access this page.'),
                __('Access Denied'),
                Page::HTTP_STATUS_UNAUTHORIZED
            );
        }*/

        $this->Html->setDTD('<!DOCTYPE html>');
        $this->Html->setAttribute('lang', Lang::get());
        $this->addElementToHead(new XMLElement('meta', null, array('charset' => 'UTF-8')));
        $this->addStylesheetToHead(self::$assets_base_url . 'editorframe.css');

        $style = new XMLElement('style', null, array('id' => 'highlighter-styles'));
        $style->setSelfClosingTag(false);
        $this->Head->appendChild($style);

        $script_content = 'window.Settings = ' . json_encode(Symphony::Configuration()->get('workspacer')) . ';' . PHP_EOL . 'window.Highlighters = {};' . PHP_EOL;
        $filepath = EXTENSIONS . '/workspacer/assets/highlighters/';
        $entries = scandir($filepath);
        foreach ($entries as $entry) {
            $file = $filepath . $entry;
            if (is_file($filepath . $entry)) {
                $info = pathinfo($file);
                if ($info['extension'] == 'js' and $info['filename'] != '') {
                    $script_content .= file_get_contents($file) . PHP_EOL;
                }
            }
        }
        $doc_text = file_get_contents(WORKSPACE . $_GET['path']);
        if ($doc_text) {
            $doc_text = addslashes($doc_text);
            $doc_text = preg_replace("/(\r\n|\n|\r)/", "\\n", $doc_text);
        }
        $script_content .= 'window.doc_text = "' . $doc_text . '"';
        $script = new XMLElement('script', $text, array('id' => 'text', 'type' => 'text'));
        $script->setSelfClosingTag(false);
        $this->Body->appendChild($script);

        $this->addElementToHead(new XMLElement(
            'script', $script_content, array('type' => 'text/javascript')
        ));

        $script = new XMLElement('script');
        $script->setSelfClosingTag(false);
        $script->setAttributeArray(array(
            'type' => 'text/javascript',
            'src' => URL . '/extensions/workspacer/assets/editorframe.js',
            'defer' => 'defer'
        ));
        $this->addElementToHead($script, null);

        $path_parts = $this->_context;
        array_shift($path_parts);
        $path = implode('/', $path_parts);
        if ($path) {
            $path_abs = WORKSPACE . '/' . $path;
            if (is_file($path_abs)) {
                $filename = basename($path);
                $this->_existing_file = $filename;
                $title = $filename;
                if (dirname($path_abs) !== WORKSPACE) {
                    $path_obj = new PathObject(dirname($path));
                }
            } else {
                $path_obj = new PathObject($path);
            }
        } else {
            $path_abs = WORKSPACE;
        }

        if (!$filename) {
            $title = 'Untitled';
        }

        $this->setTitle(__(('%1$s &ndash; %2$s &ndash; %3$s'), array($title, __('Workspace'), __('Symphony'))));
        $this->Body->setAttribute('spellcheck', 'false');

        $name = $this->_context[1];
        $title = $filename;
        $this->setTitle(__(('%1$s &ndash; %2$s &ndash; %3$s'), array($title, __('Pages'), __('Symphony'))));
        $this->Body->setAttribute('spellcheck', 'false');
        $font_size = $this->settings->font_size ? $this->settings->font_size : '8.2pt';
        $font_family = $this->settings->font_family ? $this->settings->font_family . ', monospace' : 'monospace';
        $line_height = $this->settings->line_height ? $this->settings->line_height : '148%';
        $pre = new XMLElement(
            'pre',
            null,
            array(
                'contentEditable' => 'true',
                'style' => 'font-family: ' . $font_family . ';font-size: ' . $font_size . ';line-height:' . $this->settings->line_height
            )
        );
        $pre->setSelfClosingTag(false);
        $this->Body->appendChild($pre);

    }
}
