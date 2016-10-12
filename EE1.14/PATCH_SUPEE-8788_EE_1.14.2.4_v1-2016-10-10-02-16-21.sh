#!/bin/bash
# Patch apllying tool template
# v0.1.2
# (c) Copyright 2013. Magento Inc.
#
# DO NOT CHANGE ANY LINE IN THIS FILE.

# 1. Check required system tools
_check_installed_tools() {
    local missed=""

    until [ -z "$1" ]; do
        type -t $1 >/dev/null 2>/dev/null
        if (( $? != 0 )); then
            missed="$missed $1"
        fi
        shift
    done

    echo $missed
}

REQUIRED_UTILS='sed patch'
MISSED_REQUIRED_TOOLS=`_check_installed_tools $REQUIRED_UTILS`
if (( `echo $MISSED_REQUIRED_TOOLS | wc -w` > 0 ));
then
    echo -e "Error! Some required system tools, that are utilized in this sh script, are not installed:\nTool(s) \"$MISSED_REQUIRED_TOOLS\" is(are) missed, please install it(them)."
    exit 1
fi

# 2. Determine bin path for system tools
CAT_BIN=`which cat`
PATCH_BIN=`which patch`
SED_BIN=`which sed`
PWD_BIN=`which pwd`
BASENAME_BIN=`which basename`

BASE_NAME=`$BASENAME_BIN "$0"`

# 3. Help menu
if [ "$1" = "-?" -o "$1" = "-h" -o "$1" = "--help" ]
then
    $CAT_BIN << EOFH
Usage: sh $BASE_NAME [--help] [-R|--revert] [--list]
Apply embedded patch.

-R, --revert    Revert previously applied embedded patch
--list          Show list of applied patches
--help          Show this help message
EOFH
    exit 0
fi

# 4. Get "revert" flag and "list applied patches" flag
REVERT_FLAG=
SHOW_APPLIED_LIST=0
if [ "$1" = "-R" -o "$1" = "--revert" ]
then
    REVERT_FLAG=-R
fi
if [ "$1" = "--list" ]
then
    SHOW_APPLIED_LIST=1
fi

# 5. File pathes
CURRENT_DIR=`$PWD_BIN`/
APP_ETC_DIR=`echo "$CURRENT_DIR""app/etc/"`
APPLIED_PATCHES_LIST_FILE=`echo "$APP_ETC_DIR""applied.patches.list"`

# 6. Show applied patches list if requested
if [ "$SHOW_APPLIED_LIST" -eq 1 ] ; then
    echo -e "Applied/reverted patches list:"
    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -r "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be readable so applied patches list can be shown."
            exit 1
        else
            $SED_BIN -n "/SUP-\|SUPEE-/p" $APPLIED_PATCHES_LIST_FILE
        fi
    else
        echo "<empty>"
    fi
    exit 0
fi

# 7. Check applied patches track file and its directory
_check_files() {
    if [ ! -e "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must exist for proper tool work."
        exit 1
    fi

    if [ ! -w "$APP_ETC_DIR" ]
    then
        echo "ERROR: \"$APP_ETC_DIR\" must be writeable for proper tool work."
        exit 1
    fi

    if [ -e "$APPLIED_PATCHES_LIST_FILE" ]
    then
        if [ ! -w "$APPLIED_PATCHES_LIST_FILE" ]
        then
            echo "ERROR: \"$APPLIED_PATCHES_LIST_FILE\" must be writeable for proper tool work."
            exit 1
        fi
    fi
}

_check_files

# 8. Apply/revert patch
# Note: there is no need to check files permissions for files to be patched.
# "patch" tool will not modify any file if there is not enough permissions for all files to be modified.
# Get start points for additional information and patch data
SKIP_LINES=$((`$SED_BIN -n "/^__PATCHFILE_FOLLOWS__$/=" "$CURRENT_DIR""$BASE_NAME"` + 1))
ADDITIONAL_INFO_LINE=$(($SKIP_LINES - 3))p

_apply_revert_patch() {
    DRY_RUN_FLAG=
    if [ "$1" = "dry-run" ]
    then
        DRY_RUN_FLAG=" --dry-run"
        echo "Checking if patch can be applied/reverted successfully..."
    fi
    PATCH_APPLY_REVERT_RESULT=`$SED_BIN -e '1,/^__PATCHFILE_FOLLOWS__$/d' "$CURRENT_DIR""$BASE_NAME" | $PATCH_BIN $DRY_RUN_FLAG $REVERT_FLAG -p0`
    PATCH_APPLY_REVERT_STATUS=$?
    if [ $PATCH_APPLY_REVERT_STATUS -eq 1 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully.\n\n$PATCH_APPLY_REVERT_RESULT"
        exit 1
    fi
    if [ $PATCH_APPLY_REVERT_STATUS -eq 2 ] ; then
        echo -e "ERROR: Patch can't be applied/reverted successfully."
        exit 2
    fi
}

REVERTED_PATCH_MARK=
if [ -n "$REVERT_FLAG" ]
then
    REVERTED_PATCH_MARK=" | REVERTED"
fi

_apply_revert_patch dry-run
_apply_revert_patch

# 9. Track patch applying result
echo "Patch was applied/reverted successfully."
ADDITIONAL_INFO=`$SED_BIN -n ""$ADDITIONAL_INFO_LINE"" "$CURRENT_DIR""$BASE_NAME"`
APPLIED_REVERTED_ON_DATE=`date -u +"%F %T UTC"`
APPLIED_REVERTED_PATCH_INFO=`echo -n "$APPLIED_REVERTED_ON_DATE"" | ""$ADDITIONAL_INFO""$REVERTED_PATCH_MARK"`
echo -e "$APPLIED_REVERTED_PATCH_INFO\n$PATCH_APPLY_REVERT_RESULT\n\n" >> "$APPLIED_PATCHES_LIST_FILE"

exit 0


SUPEE-8788 | EE_1.14.2.4 | v1 | f92646d2f71a4a3ed9b7dc446fc4befc9cdd84a2 | Mon Sep 26 10:22:27 2016 +0300 | e665a14abd..f92646d2f7

__PATCHFILE_FOLLOWS__
diff --git app/code/core/Enterprise/Catalog/Block/Adminhtml/Redirect/Select/Category/Tree.php app/code/core/Enterprise/Catalog/Block/Adminhtml/Redirect/Select/Category/Tree.php
index 0e97383..e4d111d 100644
--- app/code/core/Enterprise/Catalog/Block/Adminhtml/Redirect/Select/Category/Tree.php
+++ app/code/core/Enterprise/Catalog/Block/Adminhtml/Redirect/Select/Category/Tree.php
@@ -145,7 +145,7 @@ class Enterprise_Catalog_Block_Adminhtml_Redirect_Select_Category_Tree
             'parent_id'      => (int)$node->getParentId(),
             'children_count' => (int)$node->getChildrenCount(),
             'is_active'      => (bool)$node->getIsActive(),
-            'name'           => $node->getName(),
+            'name'           => $this->escapeHtml($node->getName()),
             'href'           => $this->getCategoryEditUrl($node),
             'level'          => (int)$node->getLevel(),
             'product_count'  => (int)$node->getProductCount()
diff --git app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php
index 301a64f..ebdb771 100644
--- app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php
+++ app/code/core/Enterprise/ImportExport/Model/Scheduled/Operation.php
@@ -137,12 +137,24 @@ class Enterprise_ImportExport_Model_Scheduled_Operation extends Mage_Core_Model_
     {
         $fileInfo = $this->getFileInfo();
         if (trim($fileInfo)) {
-            $this->setFileInfo(unserialize($fileInfo));
+            try {
+                $fileInfo = Mage::helper('core/unserializeArray')
+                    ->unserialize($fileInfo);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $this->setFileInfo($fileInfo);
         }
 
         $attrsInfo = $this->getEntityAttributes();
         if (trim($attrsInfo)) {
-            $this->setEntityAttributes(unserialize($attrsInfo));
+            try {
+                $attrsInfo = Mage::helper('core/unserializeArray')
+                    ->unserialize($attrsInfo);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $this->setEntityAttributes($attrsInfo);
         }
 
         return parent::_afterLoad();
diff --git app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php
index d289c15..3acf2b5 100644
--- app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php
+++ app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/Grid.php
@@ -76,7 +76,8 @@ class Enterprise_Invitation_Block_Adminhtml_Invitation_Grid extends Mage_Adminht
         $this->addColumn('email', array(
             'header' => Mage::helper('enterprise_invitation')->__('Email'),
             'index' => 'invitation_email',
-            'type'  => 'text'
+            'type'  => 'text',
+            'escape' => true
         ));
 
         $renderer = (Mage::getSingleton('admin/session')->isAllowed('customer/manage'))
diff --git app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/View.php app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/View.php
index 1821122..552851f 100644
--- app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/View.php
+++ app/code/core/Enterprise/Invitation/Block/Adminhtml/Invitation/View.php
@@ -40,7 +40,7 @@ class Enterprise_Invitation_Block_Adminhtml_Invitation_View extends Mage_Adminht
     protected function _prepareLayout()
     {
         $invitation = $this->getInvitation();
-        $this->_headerText = Mage::helper('enterprise_invitation')->__('View Invitation for %s (ID: %s)', $invitation->getEmail(), $invitation->getId());
+        $this->_headerText = Mage::helper('enterprise_invitation')->__('View Invitation for %s (ID: %s)', Mage::helper('core')->escapeHtml($invitation->getEmail()), $invitation->getId());
         $this->_addButton('back', array(
             'label' => Mage::helper('enterprise_invitation')->__('Back'),
             'onclick' => "setLocation('{$this->getUrl('*/*/')}')",
diff --git app/code/core/Enterprise/Invitation/controllers/IndexController.php app/code/core/Enterprise/Invitation/controllers/IndexController.php
index 305f2b1..5c00c9c 100644
--- app/code/core/Enterprise/Invitation/controllers/IndexController.php
+++ app/code/core/Enterprise/Invitation/controllers/IndexController.php
@@ -81,7 +81,7 @@ class Enterprise_Invitation_IndexController extends Mage_Core_Controller_Front_A
                     ))->save();
                     if ($invitation->sendInvitationEmail()) {
                         Mage::getSingleton('customer/session')->addSuccess(
-                            Mage::helper('enterprise_invitation')->__('Invitation for %s has been sent.', $email)
+                            Mage::helper('enterprise_invitation')->__('Invitation for %s has been sent.', Mage::helper('core')->escapeHtml($email))
                         );
                         $sent++;
                     }
@@ -100,7 +100,7 @@ class Enterprise_Invitation_IndexController extends Mage_Core_Controller_Front_A
                 }
                 catch (Exception $e) {
                     Mage::getSingleton('customer/session')->addError(
-                        Mage::helper('enterprise_invitation')->__('Failed to send email to %s.', $email)
+                        Mage::helper('enterprise_invitation')->__('Failed to send email to %s.', Mage::helper('core')->escapeHtml($email))
                     );
                 }
             }
diff --git app/code/core/Enterprise/PageCache/Model/Processor.php app/code/core/Enterprise/PageCache/Model/Processor.php
index 4add3ef..7dc6cd5 100644
--- app/code/core/Enterprise/PageCache/Model/Processor.php
+++ app/code/core/Enterprise/PageCache/Model/Processor.php
@@ -734,7 +734,13 @@ class Enterprise_PageCache_Model_Processor
          * Define request URI
          */
         if ($uri) {
-            if (isset($_SERVER['REQUEST_URI'])) {
+            if (isset($_SERVER['HTTP_X_ORIGINAL_URL'])) {
+                // IIS with Microsoft Rewrite Module
+                $uri.= $_SERVER['HTTP_X_ORIGINAL_URL'];
+            } elseif (isset($_SERVER['HTTP_X_REWRITE_URL'])) {
+                // IIS with ISAPI_Rewrite
+                $uri.= $_SERVER['HTTP_X_REWRITE_URL'];
+            } elseif (isset($_SERVER['REQUEST_URI'])) {
                 $uri.= $_SERVER['REQUEST_URI'];
             } elseif (!empty($_SERVER['IIS_WasUrlRewritten']) && !empty($_SERVER['UNENCODED_URL'])) {
                 $uri.= $_SERVER['UNENCODED_URL'];
diff --git app/code/core/Enterprise/Pbridge/Model/Pbridge/Api/Abstract.php app/code/core/Enterprise/Pbridge/Model/Pbridge/Api/Abstract.php
index c935eaa..d95bc26 100644
--- app/code/core/Enterprise/Pbridge/Model/Pbridge/Api/Abstract.php
+++ app/code/core/Enterprise/Pbridge/Model/Pbridge/Api/Abstract.php
@@ -55,6 +55,13 @@ class Enterprise_Pbridge_Model_Pbridge_Api_Abstract extends Varien_Object
         try {
             $http = new Varien_Http_Adapter_Curl();
             $config = array('timeout' => 60);
+            if (Mage::getStoreConfigFlag('payment/pbridge/verifyssl')) {
+                $config['verifypeer'] = true;
+                $config['verifyhost'] = 2;
+            } else {
+                $config['verifypeer'] = false;
+                $config['verifyhost'] = 0;
+            }
             $http->setConfig($config);
             $http->write(
                 Zend_Http_Client::POST,
diff --git app/code/core/Enterprise/Pbridge/etc/config.xml app/code/core/Enterprise/Pbridge/etc/config.xml
index 51e4878..292b861 100644
--- app/code/core/Enterprise/Pbridge/etc/config.xml
+++ app/code/core/Enterprise/Pbridge/etc/config.xml
@@ -168,6 +168,7 @@
                 <model>enterprise_pbridge/payment_method_pbridge</model>
                 <title>Payment Bridge</title>
                 <debug>0</debug>
+                <verifyssl>0</verifyssl>
             </pbridge>
             <pbridge_paypal_direct>
                 <model>enterprise_pbridge/payment_method_paypal</model>
diff --git app/code/core/Enterprise/Pbridge/etc/system.xml app/code/core/Enterprise/Pbridge/etc/system.xml
index f2b8ba0..6140828 100644
--- app/code/core/Enterprise/Pbridge/etc/system.xml
+++ app/code/core/Enterprise/Pbridge/etc/system.xml
@@ -70,6 +70,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
                         </gatewayurl>
+                        <verifyssl translate="label" module="enterprise_pbridge">
+                            <label>Verify SSL Connection</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>50</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </verifyssl>
                         <transferkey translate="label" module="enterprise_pbridge">
                             <label>Data Transfer Key</label>
                             <frontend_type>text</frontend_type>
diff --git app/code/core/Enterprise/Pci/Model/Encryption.php app/code/core/Enterprise/Pci/Model/Encryption.php
index ac84bc7..d208a4b 100644
--- app/code/core/Enterprise/Pci/Model/Encryption.php
+++ app/code/core/Enterprise/Pci/Model/Encryption.php
@@ -116,10 +116,10 @@ class Enterprise_Pci_Model_Encryption extends Mage_Core_Model_Encryption
         // look for salt
         $hashArr = explode(':', $hash, 2);
         if (1 === count($hashArr)) {
-            return $this->hash($password, $version) === $hash;
+            return hash_equals($this->hash($password, $version), $hash);
         }
         list($hash, $salt) = $hashArr;
-        return $this->hash($salt . $password, $version) === $hash;
+        return hash_equals($this->hash($salt . $password, $version), $hash);
     }
 
     /**
diff --git app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
index 29a3267..0c177ab 100644
--- app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
+++ app/code/core/Mage/Adminhtml/Block/Catalog/Product/Helper/Form/Gallery/Content.php
@@ -34,6 +34,12 @@
  */
 class Mage_Adminhtml_Block_Catalog_Product_Helper_Form_Gallery_Content extends Mage_Adminhtml_Block_Widget
 {
+    /**
+     * Type of uploader block
+     *
+     * @var string
+     */
+    protected $_uploaderType = 'uploader/multiple';
 
     public function __construct()
     {
@@ -44,17 +50,17 @@ class Mage_Adminhtml_Block_Catalog_Product_Helper_Form_Gallery_Content extends M
     protected function _prepareLayout()
     {
         $this->setChild('uploader',
-            $this->getLayout()->createBlock('adminhtml/media_uploader')
+            $this->getLayout()->createBlock($this->_uploaderType)
         );
 
-        $this->getUploader()->getConfig()
-            ->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/catalog_product_gallery/upload'))
-            ->setFileField('image')
-            ->setFilters(array(
-                'images' => array(
-                    'label' => Mage::helper('adminhtml')->__('Images (.gif, .jpg, .png)'),
-                    'files' => array('*.gif', '*.jpg','*.jpeg', '*.png')
-                )
+        $this->getUploader()->getUploaderConfig()
+            ->setFileParameterName('image')
+            ->setTarget(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/catalog_product_gallery/upload'));
+
+        $browseConfig = $this->getUploader()->getButtonConfig();
+        $browseConfig
+            ->setAttributes(array(
+                'accept' => $browseConfig->getMimeTypesByExtensions('gif, png, jpeg, jpg')
             ));
 
         Mage::dispatchEvent('catalog_product_gallery_prepare_layout', array('block' => $this));
@@ -65,7 +71,7 @@ class Mage_Adminhtml_Block_Catalog_Product_Helper_Form_Gallery_Content extends M
     /**
      * Retrive uploader block
      *
-     * @return Mage_Adminhtml_Block_Media_Uploader
+     * @return Mage_Uploader_Block_Multiple
      */
     public function getUploader()
     {
diff --git app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
index 1cab482..5cc06f2 100644
--- app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
+++ app/code/core/Mage/Adminhtml/Block/Cms/Wysiwyg/Images/Content/Uploader.php
@@ -31,29 +31,24 @@
  * @package    Mage_Adminhtml
  * @author     Magento Core Team <core@magentocommerce.com>
 */
-class Mage_Adminhtml_Block_Cms_Wysiwyg_Images_Content_Uploader extends Mage_Adminhtml_Block_Media_Uploader
+class Mage_Adminhtml_Block_Cms_Wysiwyg_Images_Content_Uploader extends Mage_Uploader_Block_Multiple
 {
+    /**
+     * Uploader block constructor
+     */
     public function __construct()
     {
         parent::__construct();
-        $params = $this->getConfig()->getParams();
         $type = $this->_getMediaType();
         $allowed = Mage::getSingleton('cms/wysiwyg_images_storage')->getAllowedExtensions($type);
-        $labels = array();
-        $files = array();
-        foreach ($allowed as $ext) {
-            $labels[] = '.' . $ext;
-            $files[] = '*.' . $ext;
-        }
-        $this->getConfig()
-            ->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload', array('type' => $type)))
-            ->setParams($params)
-            ->setFileField('image')
-            ->setFilters(array(
-                'images' => array(
-                    'label' => $this->helper('cms')->__('Images (%s)', implode(', ', $labels)),
-                    'files' => $files
-                )
+        $this->getUploaderConfig()
+            ->setFileParameterName('image')
+            ->setTarget(
+                Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload', array('type' => $type))
+            );
+        $this->getButtonConfig()
+            ->setAttributes(array(
+                'accept' => $this->getButtonConfig()->getMimeTypesByExtensions($allowed)
             ));
     }
 
diff --git app/code/core/Mage/Adminhtml/Block/Media/Uploader.php app/code/core/Mage/Adminhtml/Block/Media/Uploader.php
index 98564fa..48ce82b 100644
--- app/code/core/Mage/Adminhtml/Block/Media/Uploader.php
+++ app/code/core/Mage/Adminhtml/Block/Media/Uploader.php
@@ -31,189 +31,20 @@
  * @package    Mage_Adminhtml
  * @author      Magento Core Team <core@magentocommerce.com>
  */
-class Mage_Adminhtml_Block_Media_Uploader extends Mage_Adminhtml_Block_Widget
-{
-
-    protected $_config;
-
-    public function __construct()
-    {
-        parent::__construct();
-        $this->setId($this->getId() . '_Uploader');
-        $this->setTemplate('media/uploader.phtml');
-        $this->getConfig()->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload'));
-        $this->getConfig()->setParams(array('form_key' => $this->getFormKey()));
-        $this->getConfig()->setFileField('file');
-        $this->getConfig()->setFilters(array(
-            'images' => array(
-                'label' => Mage::helper('adminhtml')->__('Images (.gif, .jpg, .png)'),
-                'files' => array('*.gif', '*.jpg', '*.png')
-            ),
-            'media' => array(
-                'label' => Mage::helper('adminhtml')->__('Media (.avi, .flv, .swf)'),
-                'files' => array('*.avi', '*.flv', '*.swf')
-            ),
-            'all'    => array(
-                'label' => Mage::helper('adminhtml')->__('All Files'),
-                'files' => array('*.*')
-            )
-        ));
-    }
-
-    protected function _prepareLayout()
-    {
-        $this->setChild(
-            'browse_button',
-            $this->getLayout()->createBlock('adminhtml/widget_button')
-                ->addData(array(
-                    'id'      => $this->_getButtonId('browse'),
-                    'label'   => Mage::helper('adminhtml')->__('Browse Files...'),
-                    'type'    => 'button',
-                    'onclick' => $this->getJsObjectName() . '.browse()'
-                ))
-        );
-
-        $this->setChild(
-            'upload_button',
-            $this->getLayout()->createBlock('adminhtml/widget_button')
-                ->addData(array(
-                    'id'      => $this->_getButtonId('upload'),
-                    'label'   => Mage::helper('adminhtml')->__('Upload Files'),
-                    'type'    => 'button',
-                    'onclick' => $this->getJsObjectName() . '.upload()'
-                ))
-        );
-
-        $this->setChild(
-            'delete_button',
-            $this->getLayout()->createBlock('adminhtml/widget_button')
-                ->addData(array(
-                    'id'      => '{{id}}-delete',
-                    'class'   => 'delete',
-                    'type'    => 'button',
-                    'label'   => Mage::helper('adminhtml')->__('Remove'),
-                    'onclick' => $this->getJsObjectName() . '.removeFile(\'{{fileId}}\')'
-                ))
-        );
-
-        return parent::_prepareLayout();
-    }
-
-    protected function _getButtonId($buttonName)
-    {
-        return $this->getHtmlId() . '-' . $buttonName;
-    }
-
-    public function getBrowseButtonHtml()
-    {
-        return $this->getChildHtml('browse_button');
-    }
-
-    public function getUploadButtonHtml()
-    {
-        return $this->getChildHtml('upload_button');
-    }
-
-    public function getDeleteButtonHtml()
-    {
-        return $this->getChildHtml('delete_button');
-    }
-
-    /**
-     * Retrive uploader js object name
-     *
-     * @return string
-     */
-    public function getJsObjectName()
-    {
-        return $this->getHtmlId() . 'JsObject';
-    }
-
-    /**
-     * Retrive config json
-     *
-     * @return string
-     */
-    public function getConfigJson()
-    {
-        return Mage::helper('core')->jsonEncode($this->getConfig()->getData());
-    }
-
-    /**
-     * Retrive config object
-     *
-     * @return Varien_Config
-     */
-    public function getConfig()
-    {
-        if(is_null($this->_config)) {
-            $this->_config = new Varien_Object();
-        }
-
-        return $this->_config;
-    }
-
-    public function getPostMaxSize()
-    {
-        return ini_get('post_max_size');
-    }
-
-    public function getUploadMaxSize()
-    {
-        return ini_get('upload_max_filesize');
-    }
-
-    public function getDataMaxSize()
-    {
-        return min($this->getPostMaxSize(), $this->getUploadMaxSize());
-    }
-
-    public function getDataMaxSizeInBytes()
-    {
-        $iniSize = $this->getDataMaxSize();
-        $size = substr($iniSize, 0, strlen($iniSize)-1);
-        $parsedSize = 0;
-        switch (strtolower(substr($iniSize, strlen($iniSize)-1))) {
-            case 't':
-                $parsedSize = $size*(1024*1024*1024*1024);
-                break;
-            case 'g':
-                $parsedSize = $size*(1024*1024*1024);
-                break;
-            case 'm':
-                $parsedSize = $size*(1024*1024);
-                break;
-            case 'k':
-                $parsedSize = $size*1024;
-                break;
-            case 'b':
-            default:
-                $parsedSize = $size;
-                break;
-        }
-        return $parsedSize;
-    }
 
+/**
+ * @deprecated
+ * Class Mage_Adminhtml_Block_Media_Uploader
+ */
+class Mage_Adminhtml_Block_Media_Uploader extends Mage_Uploader_Block_Multiple
+{
     /**
-     * Retrieve full uploader SWF's file URL
-     * Implemented to solve problem with cross domain SWFs
-     * Now uploader can be only in the same URL where backend located
-     *
-     * @param string $url url to uploader in current theme
-     *
-     * @return string full URL
+     * Constructor for uploader block
      */
-    public function getUploaderUrl($url)
+    public function __construct()
     {
-        if (!is_string($url)) {
-            $url = '';
-        }
-        $design = Mage::getDesign();
-        $theme = $design->getTheme('skin');
-        if (empty($url) || !$design->validateFile($url, array('_type' => 'skin', '_theme' => $theme))) {
-            $theme = $design->getDefaultTheme();
-        }
-        return Mage::getBaseUrl(Mage_Core_Model_Store::URL_TYPE_WEB) . 'skin/' .
-            $design->getArea() . '/' . $design->getPackageName() . '/' . $theme . '/' . $url;
+        parent::__construct();
+        $this->getUploaderConfig()->setTarget(Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/upload'));
+        $this->getUploaderConfig()->setFileParameterName('file');
     }
 }
diff --git app/code/core/Mage/Adminhtml/Block/Urlrewrite/Category/Tree.php app/code/core/Mage/Adminhtml/Block/Urlrewrite/Category/Tree.php
index 06d53f1..380986b 100644
--- app/code/core/Mage/Adminhtml/Block/Urlrewrite/Category/Tree.php
+++ app/code/core/Mage/Adminhtml/Block/Urlrewrite/Category/Tree.php
@@ -119,7 +119,7 @@ class Mage_Adminhtml_Block_Urlrewrite_Category_Tree extends Mage_Adminhtml_Block
             'parent_id'      => (int)$node->getParentId(),
             'children_count' => (int)$node->getChildrenCount(),
             'is_active'      => (bool)$node->getIsActive(),
-            'name'           => $node->getName(),
+            'name'           => $this->escapeHtml($node->getName()),
             'level'          => (int)$node->getLevel(),
             'product_count'  => (int)$node->getProductCount()
         );
diff --git app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized.php app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized.php
index c2fcf07..7d143cf 100644
--- app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized.php
+++ app/code/core/Mage/Adminhtml/Model/System/Config/Backend/Serialized.php
@@ -29,8 +29,17 @@ class Mage_Adminhtml_Model_System_Config_Backend_Serialized extends Mage_Core_Mo
     protected function _afterLoad()
     {
         if (!is_array($this->getValue())) {
-            $value = $this->getValue();
-            $this->setValue(empty($value) ? false : unserialize($value));
+            $serializedValue = $this->getValue();
+            $unserializedValue = false;
+            if (!empty($serializedValue)) {
+                try {
+                    $unserializedValue = Mage::helper('core/unserializeArray')
+                        ->unserialize($serializedValue);
+                } catch (Exception $e) {
+                    Mage::logException($e);
+                }
+            }
+            $this->setValue($unserializedValue);
         }
     }
 
diff --git app/code/core/Mage/Adminhtml/controllers/DashboardController.php app/code/core/Mage/Adminhtml/controllers/DashboardController.php
index ed52b69..865e2b6 100644
--- app/code/core/Mage/Adminhtml/controllers/DashboardController.php
+++ app/code/core/Mage/Adminhtml/controllers/DashboardController.php
@@ -91,7 +91,7 @@ class Mage_Adminhtml_DashboardController extends Mage_Adminhtml_Controller_Actio
         $gaHash = $this->getRequest()->getParam('h');
         if ($gaData && $gaHash) {
             $newHash = Mage::helper('adminhtml/dashboard_data')->getChartDataHash($gaData);
-            if ($newHash == $gaHash) {
+            if (hash_equals($newHash, $gaHash)) {
                 $params = json_decode(base64_decode(urldecode($gaData)), true);
                 if ($params) {
                     $response = $httpClient->setUri(Mage_Adminhtml_Block_Dashboard_Graph::API_URL)
diff --git app/code/core/Mage/Adminhtml/controllers/IndexController.php app/code/core/Mage/Adminhtml/controllers/IndexController.php
index cbe3500..2f579cd 100644
--- app/code/core/Mage/Adminhtml/controllers/IndexController.php
+++ app/code/core/Mage/Adminhtml/controllers/IndexController.php
@@ -391,7 +391,7 @@ class Mage_Adminhtml_IndexController extends Mage_Adminhtml_Controller_Action
         }
 
         $userToken = $user->getRpToken();
-        if (strcmp($userToken, $resetPasswordLinkToken) != 0 || $user->isResetPasswordLinkTokenExpired()) {
+        if (!hash_equals($userToken, $resetPasswordLinkToken) || $user->isResetPasswordLinkTokenExpired()) {
             throw Mage::exception('Mage_Core', Mage::helper('adminhtml')->__('Your password reset link has expired.'));
         }
     }
diff --git app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php
index 0761dcf..07519f5 100644
--- app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php
+++ app/code/core/Mage/Adminhtml/controllers/Media/UploaderController.php
@@ -43,7 +43,7 @@ class Mage_Adminhtml_Media_UploaderController extends Mage_Adminhtml_Controller_
     {
         $this->loadLayout();
         $this->_addContent(
-            $this->getLayout()->createBlock('adminhtml/media_uploader')
+            $this->getLayout()->createBlock('uploader/multiple')
         );
         $this->renderLayout();
     }
diff --git app/code/core/Mage/Catalog/Helper/Image.php app/code/core/Mage/Catalog/Helper/Image.php
index 20e16a5..b216def 100644
--- app/code/core/Mage/Catalog/Helper/Image.php
+++ app/code/core/Mage/Catalog/Helper/Image.php
@@ -33,6 +33,7 @@ class Mage_Catalog_Helper_Image extends Mage_Core_Helper_Abstract
 {
     const XML_NODE_PRODUCT_BASE_IMAGE_WIDTH = 'catalog/product_image/base_width';
     const XML_NODE_PRODUCT_SMALL_IMAGE_WIDTH = 'catalog/product_image/small_width';
+    const XML_NODE_PRODUCT_MAX_DIMENSION = 'catalog/product_image/max_dimension';
 
     /**
      * Current model
@@ -634,10 +635,16 @@ class Mage_Catalog_Helper_Image extends Mage_Core_Helper_Abstract
      * @throws Mage_Core_Exception
      */
     public function validateUploadFile($filePath) {
-        if (!getimagesize($filePath)) {
+        $maxDimension = Mage::getStoreConfig(self::XML_NODE_PRODUCT_MAX_DIMENSION);
+        $imageInfo = getimagesize($filePath);
+        if (!$imageInfo) {
             Mage::throwException($this->__('Disallowed file type.'));
         }
 
+        if ($imageInfo[0] > $maxDimension || $imageInfo[1] > $maxDimension) {
+            Mage::throwException($this->__('Disalollowed file format.'));
+        }
+
         $_processor = new Varien_Image($filePath);
         return $_processor->getMimeType() !== null;
     }
diff --git app/code/core/Mage/Catalog/etc/config.xml app/code/core/Mage/Catalog/etc/config.xml
index 3968390..f225dc1 100644
--- app/code/core/Mage/Catalog/etc/config.xml
+++ app/code/core/Mage/Catalog/etc/config.xml
@@ -807,6 +807,7 @@
             <product_image>
                 <base_width>1800</base_width>
                 <small_width>210</small_width>
+                <max_dimension>5000</max_dimension>
             </product_image>
             <seo>
                 <product_url_suffix>.html</product_url_suffix>
diff --git app/code/core/Mage/Catalog/etc/system.xml app/code/core/Mage/Catalog/etc/system.xml
index 271fc19..6b1ec49 100644
--- app/code/core/Mage/Catalog/etc/system.xml
+++ app/code/core/Mage/Catalog/etc/system.xml
@@ -211,6 +211,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>1</show_in_store>
                         </small_width>
+                        <max_dimension translate="label comment">
+                            <label>Maximum resolution for upload image</label>
+                            <comment>Maximum width and height resolutions for upload image</comment>
+                            <frontend_type>text</frontend_type>
+                            <sort_order>30</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>1</show_in_store>
+                        </max_dimension>
                     </fields>
                 </product_image>
                 <placeholder translate="label">
diff --git app/code/core/Mage/Centinel/Model/Api.php app/code/core/Mage/Centinel/Model/Api.php
index 57c92ca..f82c966 100644
--- app/code/core/Mage/Centinel/Model/Api.php
+++ app/code/core/Mage/Centinel/Model/Api.php
@@ -25,11 +25,6 @@
  */
 
 /**
- * 3D Secure Validation Library for Payment
- */
-include_once '3Dsecure/CentinelClient.php';
-
-/**
  * 3D Secure Validation Api
  */
 class Mage_Centinel_Model_Api extends Varien_Object
@@ -73,19 +68,19 @@ class Mage_Centinel_Model_Api extends Varien_Object
     /**
      * Centinel validation client
      *
-     * @var CentinelClient
+     * @var Mage_Centinel_Model_Api_Client
      */
     protected $_clientInstance = null;
 
     /**
      * Return Centinel thin client object
      *
-     * @return CentinelClient
+     * @return Mage_Centinel_Model_Api_Client
      */
     protected function _getClientInstance()
     {
         if (empty($this->_clientInstance)) {
-            $this->_clientInstance = new CentinelClient();
+            $this->_clientInstance = new Mage_Centinel_Model_Api_Client();
         }
         return $this->_clientInstance;
     }
@@ -136,7 +131,7 @@ class Mage_Centinel_Model_Api extends Varien_Object
      * @param $method string
      * @param $data array
      *
-     * @return CentinelClient
+     * @return Mage_Centinel_Model_Api_Client
      */
     protected function _call($method, $data)
     {
diff --git app/code/core/Mage/Centinel/Model/Api/Client.php app/code/core/Mage/Centinel/Model/Api/Client.php
new file mode 100644
index 0000000..ae8dcaf
--- /dev/null
+++ app/code/core/Mage/Centinel/Model/Api/Client.php
@@ -0,0 +1,79 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Centinel
+ * @copyright Copyright (c) 2006-2014 X.commerce, Inc. (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/**
+ * 3D Secure Validation Library for Payment
+ */
+include_once '3Dsecure/CentinelClient.php';
+
+/**
+ * 3D Secure Validation Api
+ */
+class Mage_Centinel_Model_Api_Client extends CentinelClient
+{
+    public function sendHttp($url, $connectTimeout = "", $timeout)
+    {
+        // verify that the URL uses a supported protocol.
+        if ((strpos($url, "http://") === 0) || (strpos($url, "https://") === 0)) {
+
+            //Construct the payload to POST to the url.
+            $data = $this->getRequestXml();
+
+            // create a new cURL resource
+            $ch = curl_init($url);
+
+            // set URL and other appropriate options
+            curl_setopt($ch, CURLOPT_POST ,1);
+            curl_setopt($ch, CURLOPT_POSTFIELDS, $data);
+            curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
+            curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 1);
+            curl_setopt($ch, CURLOPT_TIMEOUT, $timeout);
+
+            // Execute the request.
+            $result = curl_exec($ch);
+            $succeeded = curl_errno($ch) == 0 ? true : false;
+
+            // close cURL resource, and free up system resources
+            curl_close($ch);
+
+            // If Communication was not successful set error result, otherwise
+            if (!$succeeded) {
+                $result = $this->setErrorResponse(CENTINEL_ERROR_CODE_8030, CENTINEL_ERROR_CODE_8030_DESC);
+            }
+
+            // Assert that we received an expected Centinel Message in reponse.
+            if (strpos($result, "<CardinalMPI>") === false) {
+                $result = $this->setErrorResponse(CENTINEL_ERROR_CODE_8010, CENTINEL_ERROR_CODE_8010_DESC);
+            }
+        } else {
+            $result = $this->setErrorResponse(CENTINEL_ERROR_CODE_8000, CENTINEL_ERROR_CODE_8000_DESC);
+        }
+        $parser = new XMLParser;
+        $parser->deserializeXml($result);
+        $this->response = $parser->deserializedResponse;
+    }
+}
diff --git app/code/core/Mage/Core/Block/Abstract.php app/code/core/Mage/Core/Block/Abstract.php
index cd590b3..980caa8 100644
--- app/code/core/Mage/Core/Block/Abstract.php
+++ app/code/core/Mage/Core/Block/Abstract.php
@@ -37,6 +37,10 @@
 abstract class Mage_Core_Block_Abstract extends Varien_Object
 {
     /**
+     * Prefix for cache key
+     */
+    const CACHE_KEY_PREFIX = 'BLOCK_';
+    /**
      * Cache group Tag
      */
     const CACHE_GROUP = 'block_html';
@@ -1289,7 +1293,13 @@ abstract class Mage_Core_Block_Abstract extends Varien_Object
     public function getCacheKey()
     {
         if ($this->hasData('cache_key')) {
-            return $this->getData('cache_key');
+            $cacheKey = $this->getData('cache_key');
+            if (strpos($cacheKey, self::CACHE_KEY_PREFIX) !== 0) {
+                $cacheKey = self::CACHE_KEY_PREFIX . $cacheKey;
+                $this->setData('cache_key', $cacheKey);
+            }
+
+            return $cacheKey;
         }
         /**
          * don't prevent recalculation by saving generated cache key
diff --git app/code/core/Mage/Core/Helper/Url.php app/code/core/Mage/Core/Helper/Url.php
index 78143f6..7a78dc5 100644
--- app/code/core/Mage/Core/Helper/Url.php
+++ app/code/core/Mage/Core/Helper/Url.php
@@ -51,7 +51,7 @@ class Mage_Core_Helper_Url extends Mage_Core_Helper_Abstract
             $port = (in_array($port, $defaultPorts)) ? '' : ':' . $port;
         }
         $url = $request->getScheme() . '://' . $request->getHttpHost() . $port . $request->getServer('REQUEST_URI');
-        return $url;
+        return $this->escapeUrl($url);
 //        return $this->_getUrl('*/*/*', array('_current' => true, '_use_rewrite' => true));
     }
 
diff --git app/code/core/Mage/Core/Model/Encryption.php app/code/core/Mage/Core/Model/Encryption.php
index b8bd9d3..ff3021a 100644
--- app/code/core/Mage/Core/Model/Encryption.php
+++ app/code/core/Mage/Core/Model/Encryption.php
@@ -98,9 +98,9 @@ class Mage_Core_Model_Encryption
         $hashArr = explode(':', $hash);
         switch (count($hashArr)) {
             case 1:
-                return $this->hash($password) === $hash;
+                return hash_equals($this->hash($password), $hash);
             case 2:
-                return $this->hash($hashArr[1] . $password) === $hashArr[0];
+                return hash_equals($this->hash($hashArr[1] . $password),  $hashArr[0]);
         }
         Mage::throwException('Invalid hash.');
     }
diff --git app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
index 2c33825..b10cd5a 100644
--- app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
+++ app/code/core/Mage/Core/Model/Input/Filter/MaliciousCode.php
@@ -65,7 +65,13 @@ class Mage_Core_Model_Input_Filter_MaliciousCode implements Zend_Filter_Interfac
      */
     public function filter($value)
     {
-        return preg_replace($this->_expressions, '', $value);
+        $result = false;
+        do {
+            $subject = $result ? $result : $value;
+            $result = preg_replace($this->_expressions, '', $subject, -1, $count);
+        } while ($count !== 0);
+
+        return $result;
     }
 
     /**
diff --git app/code/core/Mage/Core/functions.php app/code/core/Mage/Core/functions.php
index 189cf05..0273751 100644
--- app/code/core/Mage/Core/functions.php
+++ app/code/core/Mage/Core/functions.php
@@ -375,3 +375,38 @@ if ( !function_exists('sys_get_temp_dir') ) {
         }
     }
 }
+
+if (!function_exists('hash_equals')) {
+    /**
+     * Compares two strings using the same time whether they're equal or not.
+     * A difference in length will leak
+     *
+     * @param string $known_string
+     * @param string $user_string
+     * @return boolean Returns true when the two strings are equal, false otherwise.
+     */
+    function hash_equals($known_string, $user_string)
+    {
+        $result = 0;
+
+        if (!is_string($known_string)) {
+            trigger_error("hash_equals(): Expected known_string to be a string", E_USER_WARNING);
+            return false;
+        }
+
+        if (!is_string($user_string)) {
+            trigger_error("hash_equals(): Expected user_string to be a string", E_USER_WARNING);
+            return false;
+        }
+
+        if (strlen($known_string) != strlen($user_string)) {
+            return false;
+        }
+
+        for ($i = 0; $i < strlen($known_string); $i++) {
+            $result |= (ord($known_string[$i]) ^ ord($user_string[$i]));
+        }
+
+        return 0 === $result;
+    }
+}
diff --git app/code/core/Mage/Customer/Block/Address/Book.php app/code/core/Mage/Customer/Block/Address/Book.php
index a7ced69..53f8a0b 100644
--- app/code/core/Mage/Customer/Block/Address/Book.php
+++ app/code/core/Mage/Customer/Block/Address/Book.php
@@ -56,7 +56,8 @@ class Mage_Customer_Block_Address_Book extends Mage_Core_Block_Template
 
     public function getDeleteUrl()
     {
-        return $this->getUrl('customer/address/delete');
+        return $this->getUrl('customer/address/delete',
+            array(Mage_Core_Model_Url::FORM_KEY => Mage::getSingleton('core/session')->getFormKey()));
     }
 
     public function getAddressEditUrl($address)
diff --git app/code/core/Mage/Customer/controllers/AddressController.php app/code/core/Mage/Customer/controllers/AddressController.php
index 9ec5004..8df749b 100644
--- app/code/core/Mage/Customer/controllers/AddressController.php
+++ app/code/core/Mage/Customer/controllers/AddressController.php
@@ -163,6 +163,9 @@ class Mage_Customer_AddressController extends Mage_Core_Controller_Front_Action
 
     public function deleteAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*/');
+        }
         $addressId = $this->getRequest()->getParam('id', false);
 
         if ($addressId) {
diff --git app/code/core/Mage/Dataflow/Model/Profile.php app/code/core/Mage/Dataflow/Model/Profile.php
index 5b658f4..a0bbbd2 100644
--- app/code/core/Mage/Dataflow/Model/Profile.php
+++ app/code/core/Mage/Dataflow/Model/Profile.php
@@ -64,10 +64,14 @@ class Mage_Dataflow_Model_Profile extends Mage_Core_Model_Abstract
 
     protected function _afterLoad()
     {
+        $guiData = '';
         if (is_string($this->getGuiData())) {
-            $guiData = unserialize($this->getGuiData());
-        } else {
-            $guiData = '';
+            try {
+                $guiData = Mage::helper('core/unserializeArray')
+                    ->unserialize($this->getGuiData());
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
         }
         $this->setGuiData($guiData);
 
@@ -127,7 +131,13 @@ class Mage_Dataflow_Model_Profile extends Mage_Core_Model_Abstract
     protected function _afterSave()
     {
         if (is_string($this->getGuiData())) {
-            $this->setGuiData(unserialize($this->getGuiData()));
+            try {
+                $guiData = Mage::helper('core/unserializeArray')
+                    ->unserialize($this->getGuiData());
+                $this->setGuiData($guiData);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
         }
 
         $profileHistory = Mage::getModel('dataflow/profile_history');
diff --git app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php
index d97b155..4528e66 100644
--- app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php
+++ app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Links.php
@@ -32,7 +32,7 @@
  * @author      Magento Core Team <core@magentocommerce.com>
  */
 class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Links
-    extends Mage_Adminhtml_Block_Template
+    extends Mage_Uploader_Block_Single
 {
     /**
      * Purchased Separately Attribute cache
@@ -242,6 +242,7 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Li
      */
      protected function _prepareLayout()
     {
+        parent::_prepareLayout();
         $this->setChild(
             'upload_button',
             $this->getLayout()->createBlock('adminhtml/widget_button')->addData(array(
@@ -251,6 +252,10 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Li
                 'onclick' => 'Downloadable.massUploadByType(\'links\');Downloadable.massUploadByType(\'linkssample\')'
             ))
         );
+        $this->_addElementIdsMapping(array(
+            'container' => $this->getHtmlId() . '-new',
+            'delete'    => $this->getHtmlId() . '-delete'
+        ));
     }
 
     /**
@@ -270,33 +275,56 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Li
      */
     public function getConfigJson($type='links')
     {
-        $this->getConfig()->setUrl(Mage::getModel('adminhtml/url')->addSessionParam()
-            ->getUrl('*/downloadable_file/upload', array('type' => $type, '_secure' => true)));
-        $this->getConfig()->setParams(array('form_key' => $this->getFormKey()));
-        $this->getConfig()->setFileField($type);
-        $this->getConfig()->setFilters(array(
-            'all'    => array(
-                'label' => Mage::helper('adminhtml')->__('All Files'),
-                'files' => array('*.*')
+
+        $this->getUploaderConfig()
+            ->setFileParameterName($type)
+            ->setTarget(
+                Mage::getModel('adminhtml/url')
+                    ->addSessionParam()
+                    ->getUrl('*/downloadable_file/upload', array('type' => $type, '_secure' => true))
+            );
+        $this->getMiscConfig()
+            ->setReplaceBrowseWithRemove(true)
+        ;
+        return Mage::helper('core')->jsonEncode(parent::getJsonConfig());
+    }
+
+    /**
+     * @return string
+     */
+    public function getBrowseButtonHtml($type = '')
+    {
+        return $this->getChild('browse_button')
+            // Workaround for IE9
+            ->setBeforeHtml(
+                '<div style="display:inline-block; " id="downloadable_link_{{id}}_' . $type . 'file-browse">'
             )
-        ));
-        $this->getConfig()->setReplaceBrowseWithRemove(true);
-        $this->getConfig()->setWidth('32');
-        $this->getConfig()->setHideUploadButton(true);
-        return Mage::helper('core')->jsonEncode($this->getConfig()->getData());
+            ->setAfterHtml('</div>')
+            ->setId('downloadable_link_{{id}}_' . $type . 'file-browse_button')
+            ->toHtml();
     }
 
+
     /**
-     * Retrive config object
+     * @return string
+     */
+    public function getDeleteButtonHtml($type = '')
+    {
+        return $this->getChild('delete_button')
+            ->setLabel('')
+            ->setId('downloadable_link_{{id}}_' . $type . 'file-delete')
+            ->setStyle('display:none; width:31px;')
+            ->toHtml();
+    }
+
+    /**
+     * Retrieve config object
      *
-     * @return Varien_Config
+     * @deprecated
+     * @return $this
      */
     public function getConfig()
     {
-        if(is_null($this->_config)) {
-            $this->_config = new Varien_Object();
-        }
-
-        return $this->_config;
+        return $this;
     }
 }
diff --git app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Samples.php app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Samples.php
index cd24fbe..7c22afe 100644
--- app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Samples.php
+++ app/code/core/Mage/Downloadable/Block/Adminhtml/Catalog/Product/Edit/Tab/Downloadable/Samples.php
@@ -32,7 +32,7 @@
  * @author      Magento Core Team <core@magentocommerce.com>
  */
 class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Samples
-    extends Mage_Adminhtml_Block_Widget
+    extends Mage_Uploader_Block_Single
 {
     /**
      * Class constructor
@@ -148,6 +148,7 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Sa
      */
     protected function _prepareLayout()
     {
+        parent::_prepareLayout();
         $this->setChild(
             'upload_button',
             $this->getLayout()->createBlock('adminhtml/widget_button')
@@ -158,6 +159,11 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Sa
                     'onclick' => 'Downloadable.massUploadByType(\'samples\')'
                 ))
         );
+
+        $this->_addElementIdsMapping(array(
+            'container' => $this->getHtmlId() . '-new',
+            'delete'    => $this->getHtmlId() . '-delete'
+        ));
     }
 
     /**
@@ -171,40 +177,59 @@ class Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Sa
     }
 
     /**
-     * Retrive config json
+     * Retrieve config json
      *
      * @return string
      */
     public function getConfigJson()
     {
-        $this->getConfig()->setUrl(Mage::getModel('adminhtml/url')
-            ->addSessionParam()
-            ->getUrl('*/downloadable_file/upload', array('type' => 'samples', '_secure' => true)));
-        $this->getConfig()->setParams(array('form_key' => $this->getFormKey()));
-        $this->getConfig()->setFileField('samples');
-        $this->getConfig()->setFilters(array(
-            'all'    => array(
-                'label' => Mage::helper('adminhtml')->__('All Files'),
-                'files' => array('*.*')
-            )
-        ));
-        $this->getConfig()->setReplaceBrowseWithRemove(true);
-        $this->getConfig()->setWidth('32');
-        $this->getConfig()->setHideUploadButton(true);
-        return Mage::helper('core')->jsonEncode($this->getConfig()->getData());
+        $this->getUploaderConfig()
+            ->setFileParameterName('samples')
+            ->setTarget(
+                Mage::getModel('adminhtml/url')
+                    ->addSessionParam()
+                    ->getUrl('*/downloadable_file/upload', array('type' => 'samples', '_secure' => true))
+            );
+        $this->getMiscConfig()
+            ->setReplaceBrowseWithRemove(true)
+        ;
+        return Mage::helper('core')->jsonEncode(parent::getJsonConfig());
     }
 
     /**
-     * Retrive config object
+     * @return string
+     */
+    public function getBrowseButtonHtml()
+    {
+        return $this->getChild('browse_button')
+            // Workaround for IE9
+            ->setBeforeHtml('<div style="display:inline-block; " id="downloadable_sample_{{id}}_file-browse">')
+            ->setAfterHtml('</div>')
+            ->setId('downloadable_sample_{{id}}_file-browse_button')
+            ->toHtml();
+    }
+
+
+    /**
+     * @return string
+     */
+    public function getDeleteButtonHtml()
+    {
+        return $this->getChild('delete_button')
+            ->setLabel('')
+            ->setId('downloadable_sample_{{id}}_file-delete')
+            ->setStyle('display:none; width:31px;')
+            ->toHtml();
+    }
+
+    /**
+     * Retrieve config object
      *
-     * @return Varien_Config
+     * @deprecated
+     * @return $this
      */
     public function getConfig()
     {
-        if(is_null($this->_config)) {
-            $this->_config = new Varien_Object();
-        }
-
-        return $this->_config;
+        return $this;
     }
 }
diff --git app/code/core/Mage/Downloadable/Helper/File.php app/code/core/Mage/Downloadable/Helper/File.php
index 2d4a622..425c5b9 100644
--- app/code/core/Mage/Downloadable/Helper/File.php
+++ app/code/core/Mage/Downloadable/Helper/File.php
@@ -33,15 +33,35 @@
  */
 class Mage_Downloadable_Helper_File extends Mage_Core_Helper_Abstract
 {
+    /**
+     * @see Mage_Uploader_Helper_File::getMimeTypes
+     * @var array
+     */
+    protected $_mimeTypes;
+
+    /**
+     * @var Mage_Uploader_Helper_File
+     */
+    protected $_fileHelper;
+
+    /**
+     * Populate self::_mimeTypes array with values that set in config or pre-defined
+     */
     public function __construct()
     {
-        $nodes = Mage::getConfig()->getNode('global/mime/types');
-        if ($nodes) {
-            $nodes = (array)$nodes;
-            foreach ($nodes as $key => $value) {
-                self::$_mimeTypes[$key] = $value;
-            }
+        $this->_mimeTypes = $this->_getFileHelper()->getMimeTypes();
+    }
+
+    /**
+     * @return Mage_Uploader_Helper_File
+     */
+    protected function _getFileHelper()
+    {
+        if (!$this->_fileHelper) {
+            $this->_fileHelper = Mage::helper('uploader/file');
         }
+
+        return $this->_fileHelper;
     }
 
     /**
@@ -152,628 +172,48 @@ class Mage_Downloadable_Helper_File extends Mage_Core_Helper_Abstract
         return $file;
     }
 
+    /**
+     * Get MIME type for $filePath
+     *
+     * @param $filePath
+     * @return string
+     */
     public function getFileType($filePath)
     {
         $ext = substr($filePath, strrpos($filePath, '.')+1);
         return $this->_getFileTypeByExt($ext);
     }
 
+    /**
+     * Get MIME type by file extension
+     *
+     * @param $ext
+     * @return string
+     * @deprecated
+     */
     protected function _getFileTypeByExt($ext)
     {
-        $type = 'x' . $ext;
-        if (isset(self::$_mimeTypes[$type])) {
-            return self::$_mimeTypes[$type];
-        }
-        return 'application/octet-stream';
+        return $this->_getFileHelper()->getMimeTypeByExtension($ext);
     }
 
+    /**
+     * Get all MIME types
+     *
+     * @return array
+     */
     public function getAllFileTypes()
     {
-        return array_values(self::getAllMineTypes());
+        return array_values($this->getAllMineTypes());
     }
 
+    /**
+     * Get list of all MIME types
+     *
+     * @return array
+     */
     public function getAllMineTypes()
     {
-        return self::$_mimeTypes;
+        return $this->_mimeTypes;
     }
 
-    protected static $_mimeTypes =
-        array(
-            'x123' => 'application/vnd.lotus-1-2-3',
-            'x3dml' => 'text/vnd.in3d.3dml',
-            'x3g2' => 'video/3gpp2',
-            'x3gp' => 'video/3gpp',
-            'xace' => 'application/x-ace-compressed',
-            'xacu' => 'application/vnd.acucobol',
-            'xaep' => 'application/vnd.audiograph',
-            'xai' => 'application/postscript',
-            'xaif' => 'audio/x-aiff',
-
-            'xaifc' => 'audio/x-aiff',
-            'xaiff' => 'audio/x-aiff',
-            'xami' => 'application/vnd.amiga.ami',
-            'xapr' => 'application/vnd.lotus-approach',
-            'xasf' => 'video/x-ms-asf',
-            'xaso' => 'application/vnd.accpac.simply.aso',
-            'xasx' => 'video/x-ms-asf',
-            'xatom' => 'application/atom+xml',
-            'xatomcat' => 'application/atomcat+xml',
-
-            'xatomsvc' => 'application/atomsvc+xml',
-            'xatx' => 'application/vnd.antix.game-component',
-            'xau' => 'audio/basic',
-            'xavi' => 'video/x-msvideo',
-            'xbat' => 'application/x-msdownload',
-            'xbcpio' => 'application/x-bcpio',
-            'xbdm' => 'application/vnd.syncml.dm+wbxml',
-            'xbh2' => 'application/vnd.fujitsu.oasysprs',
-            'xbmi' => 'application/vnd.bmi',
-
-            'xbmp' => 'image/bmp',
-            'xbox' => 'application/vnd.previewsystems.box',
-            'xboz' => 'application/x-bzip2',
-            'xbtif' => 'image/prs.btif',
-            'xbz' => 'application/x-bzip',
-            'xbz2' => 'application/x-bzip2',
-            'xcab' => 'application/vnd.ms-cab-compressed',
-            'xccxml' => 'application/ccxml+xml',
-            'xcdbcmsg' => 'application/vnd.contact.cmsg',
-
-            'xcdkey' => 'application/vnd.mediastation.cdkey',
-            'xcdx' => 'chemical/x-cdx',
-            'xcdxml' => 'application/vnd.chemdraw+xml',
-            'xcdy' => 'application/vnd.cinderella',
-            'xcer' => 'application/pkix-cert',
-            'xcgm' => 'image/cgm',
-            'xchat' => 'application/x-chat',
-            'xchm' => 'application/vnd.ms-htmlhelp',
-            'xchrt' => 'application/vnd.kde.kchart',
-
-            'xcif' => 'chemical/x-cif',
-            'xcii' => 'application/vnd.anser-web-certificate-issue-initiation',
-            'xcil' => 'application/vnd.ms-artgalry',
-            'xcla' => 'application/vnd.claymore',
-            'xclkk' => 'application/vnd.crick.clicker.keyboard',
-            'xclkp' => 'application/vnd.crick.clicker.palette',
-            'xclkt' => 'application/vnd.crick.clicker.template',
-            'xclkw' => 'application/vnd.crick.clicker.wordbank',
-            'xclkx' => 'application/vnd.crick.clicker',
-
-            'xclp' => 'application/x-msclip',
-            'xcmc' => 'application/vnd.cosmocaller',
-            'xcmdf' => 'chemical/x-cmdf',
-            'xcml' => 'chemical/x-cml',
-            'xcmp' => 'application/vnd.yellowriver-custom-menu',
-            'xcmx' => 'image/x-cmx',
-            'xcom' => 'application/x-msdownload',
-            'xconf' => 'text/plain',
-            'xcpio' => 'application/x-cpio',
-
-            'xcpt' => 'application/mac-compactpro',
-            'xcrd' => 'application/x-mscardfile',
-            'xcrl' => 'application/pkix-crl',
-            'xcrt' => 'application/x-x509-ca-cert',
-            'xcsh' => 'application/x-csh',
-            'xcsml' => 'chemical/x-csml',
-            'xcss' => 'text/css',
-            'xcsv' => 'text/csv',
-            'xcurl' => 'application/vnd.curl',
-
-            'xcww' => 'application/prs.cww',
-            'xdaf' => 'application/vnd.mobius.daf',
-            'xdavmount' => 'application/davmount+xml',
-            'xdd2' => 'application/vnd.oma.dd2+xml',
-            'xddd' => 'application/vnd.fujixerox.ddd',
-            'xdef' => 'text/plain',
-            'xder' => 'application/x-x509-ca-cert',
-            'xdfac' => 'application/vnd.dreamfactory',
-            'xdis' => 'application/vnd.mobius.dis',
-
-            'xdjv' => 'image/vnd.djvu',
-            'xdjvu' => 'image/vnd.djvu',
-            'xdll' => 'application/x-msdownload',
-            'xdna' => 'application/vnd.dna',
-            'xdoc' => 'application/msword',
-            'xdot' => 'application/msword',
-            'xdp' => 'application/vnd.osgi.dp',
-            'xdpg' => 'application/vnd.dpgraph',
-            'xdsc' => 'text/prs.lines.tag',
-
-            'xdtd' => 'application/xml-dtd',
-            'xdvi' => 'application/x-dvi',
-            'xdwf' => 'model/vnd.dwf',
-            'xdwg' => 'image/vnd.dwg',
-            'xdxf' => 'image/vnd.dxf',
-            'xdxp' => 'application/vnd.spotfire.dxp',
-            'xecelp4800' => 'audio/vnd.nuera.ecelp4800',
-            'xecelp7470' => 'audio/vnd.nuera.ecelp7470',
-            'xecelp9600' => 'audio/vnd.nuera.ecelp9600',
-
-            'xecma' => 'application/ecmascript',
-            'xedm' => 'application/vnd.novadigm.edm',
-            'xedx' => 'application/vnd.novadigm.edx',
-            'xefif' => 'application/vnd.picsel',
-            'xei6' => 'application/vnd.pg.osasli',
-            'xeml' => 'message/rfc822',
-            'xeol' => 'audio/vnd.digital-winds',
-            'xeot' => 'application/vnd.ms-fontobject',
-            'xeps' => 'application/postscript',
-
-            'xesf' => 'application/vnd.epson.esf',
-            'xetx' => 'text/x-setext',
-            'xexe' => 'application/x-msdownload',
-            'xext' => 'application/vnd.novadigm.ext',
-            'xez' => 'application/andrew-inset',
-            'xez2' => 'application/vnd.ezpix-album',
-            'xez3' => 'application/vnd.ezpix-package',
-            'xfbs' => 'image/vnd.fastbidsheet',
-            'xfdf' => 'application/vnd.fdf',
-
-            'xfe_launch' => 'application/vnd.denovo.fcselayout-link',
-            'xfg5' => 'application/vnd.fujitsu.oasysgp',
-            'xfli' => 'video/x-fli',
-            'xflo' => 'application/vnd.micrografx.flo',
-            'xflw' => 'application/vnd.kde.kivio',
-            'xflx' => 'text/vnd.fmi.flexstor',
-            'xfly' => 'text/vnd.fly',
-            'xfnc' => 'application/vnd.frogans.fnc',
-            'xfpx' => 'image/vnd.fpx',
-
-            'xfsc' => 'application/vnd.fsc.weblaunch',
-            'xfst' => 'image/vnd.fst',
-            'xftc' => 'application/vnd.fluxtime.clip',
-            'xfti' => 'application/vnd.anser-web-funds-transfer-initiation',
-            'xfvt' => 'video/vnd.fvt',
-            'xfzs' => 'application/vnd.fuzzysheet',
-            'xg3' => 'image/g3fax',
-            'xgac' => 'application/vnd.groove-account',
-            'xgdl' => 'model/vnd.gdl',
-
-            'xghf' => 'application/vnd.groove-help',
-            'xgif' => 'image/gif',
-            'xgim' => 'application/vnd.groove-identity-message',
-            'xgph' => 'application/vnd.flographit',
-            'xgram' => 'application/srgs',
-            'xgrv' => 'application/vnd.groove-injector',
-            'xgrxml' => 'application/srgs+xml',
-            'xgtar' => 'application/x-gtar',
-            'xgtm' => 'application/vnd.groove-tool-message',
-
-            'xgtw' => 'model/vnd.gtw',
-            'xh261' => 'video/h261',
-            'xh263' => 'video/h263',
-            'xh264' => 'video/h264',
-            'xhbci' => 'application/vnd.hbci',
-            'xhdf' => 'application/x-hdf',
-            'xhlp' => 'application/winhlp',
-            'xhpgl' => 'application/vnd.hp-hpgl',
-            'xhpid' => 'application/vnd.hp-hpid',
-
-            'xhps' => 'application/vnd.hp-hps',
-            'xhqx' => 'application/mac-binhex40',
-            'xhtke' => 'application/vnd.kenameaapp',
-            'xhtm' => 'text/html',
-            'xhtml' => 'text/html',
-            'xhvd' => 'application/vnd.yamaha.hv-dic',
-            'xhvp' => 'application/vnd.yamaha.hv-voice',
-            'xhvs' => 'application/vnd.yamaha.hv-script',
-            'xice' => '#x-conference/x-cooltalk',
-
-            'xico' => 'image/x-icon',
-            'xics' => 'text/calendar',
-            'xief' => 'image/ief',
-            'xifb' => 'text/calendar',
-            'xifm' => 'application/vnd.shana.informed.formdata',
-            'xigl' => 'application/vnd.igloader',
-            'xigx' => 'application/vnd.micrografx.igx',
-            'xiif' => 'application/vnd.shana.informed.interchange',
-            'ximp' => 'application/vnd.accpac.simply.imp',
-
-            'xims' => 'application/vnd.ms-ims',
-            'xin' => 'text/plain',
-            'xipk' => 'application/vnd.shana.informed.package',
-            'xirm' => 'application/vnd.ibm.rights-management',
-            'xirp' => 'application/vnd.irepository.package+xml',
-            'xitp' => 'application/vnd.shana.informed.formtemplate',
-            'xivp' => 'application/vnd.immervision-ivp',
-            'xivu' => 'application/vnd.immervision-ivu',
-            'xjad' => 'text/vnd.sun.j2me.app-descriptor',
-
-            'xjam' => 'application/vnd.jam',
-            'xjava' => 'text/x-java-source',
-            'xjisp' => 'application/vnd.jisp',
-            'xjlt' => 'application/vnd.hp-jlyt',
-            'xjoda' => 'application/vnd.joost.joda-archive',
-            'xjpe' => 'image/jpeg',
-            'xjpeg' => 'image/jpeg',
-            'xjpg' => 'image/jpeg',
-            'xjpgm' => 'video/jpm',
-
-            'xjpgv' => 'video/jpeg',
-            'xjpm' => 'video/jpm',
-            'xjs' => 'application/javascript',
-            'xjson' => 'application/json',
-            'xkar' => 'audio/midi',
-            'xkarbon' => 'application/vnd.kde.karbon',
-            'xkfo' => 'application/vnd.kde.kformula',
-            'xkia' => 'application/vnd.kidspiration',
-            'xkml' => 'application/vnd.google-earth.kml+xml',
-
-            'xkmz' => 'application/vnd.google-earth.kmz',
-            'xkon' => 'application/vnd.kde.kontour',
-            'xksp' => 'application/vnd.kde.kspread',
-            'xlatex' => 'application/x-latex',
-            'xlbd' => 'application/vnd.llamagraphics.life-balance.desktop',
-            'xlbe' => 'application/vnd.llamagraphics.life-balance.exchange+xml',
-            'xles' => 'application/vnd.hhe.lesson-player',
-            'xlist' => 'text/plain',
-            'xlog' => 'text/plain',
-
-            'xlrm' => 'application/vnd.ms-lrm',
-            'xltf' => 'application/vnd.frogans.ltf',
-            'xlvp' => 'audio/vnd.lucent.voice',
-            'xlwp' => 'application/vnd.lotus-wordpro',
-            'xm13' => 'application/x-msmediaview',
-            'xm14' => 'application/x-msmediaview',
-            'xm1v' => 'video/mpeg',
-            'xm2a' => 'audio/mpeg',
-            'xm3a' => 'audio/mpeg',
-
-            'xm3u' => 'audio/x-mpegurl',
-            'xm4u' => 'video/vnd.mpegurl',
-            'xmag' => 'application/vnd.ecowin.chart',
-            'xmathml' => 'application/mathml+xml',
-            'xmbk' => 'application/vnd.mobius.mbk',
-            'xmbox' => 'application/mbox',
-            'xmc1' => 'application/vnd.medcalcdata',
-            'xmcd' => 'application/vnd.mcd',
-            'xmdb' => 'application/x-msaccess',
-
-            'xmdi' => 'image/vnd.ms-modi',
-            'xmesh' => 'model/mesh',
-            'xmfm' => 'application/vnd.mfmp',
-            'xmgz' => 'application/vnd.proteus.magazine',
-            'xmid' => 'audio/midi',
-            'xmidi' => 'audio/midi',
-            'xmif' => 'application/vnd.mif',
-            'xmime' => 'message/rfc822',
-            'xmj2' => 'video/mj2',
-
-            'xmjp2' => 'video/mj2',
-            'xmlp' => 'application/vnd.dolby.mlp',
-            'xmmd' => 'application/vnd.chipnuts.karaoke-mmd',
-            'xmmf' => 'application/vnd.smaf',
-            'xmmr' => 'image/vnd.fujixerox.edmics-mmr',
-            'xmny' => 'application/x-msmoney',
-            'xmov' => 'video/quicktime',
-            'xmovie' => 'video/x-sgi-movie',
-            'xmp2' => 'audio/mpeg',
-
-            'xmp2a' => 'audio/mpeg',
-            'xmp3' => 'audio/mpeg',
-            'xmp4' => 'video/mp4',
-            'xmp4a' => 'audio/mp4',
-            'xmp4s' => 'application/mp4',
-            'xmp4v' => 'video/mp4',
-            'xmpc' => 'application/vnd.mophun.certificate',
-            'xmpe' => 'video/mpeg',
-            'xmpeg' => 'video/mpeg',
-
-            'xmpg' => 'video/mpeg',
-            'xmpg4' => 'video/mp4',
-            'xmpga' => 'audio/mpeg',
-            'xmpkg' => 'application/vnd.apple.installer+xml',
-            'xmpm' => 'application/vnd.blueice.multipass',
-            'xmpn' => 'application/vnd.mophun.application',
-            'xmpp' => 'application/vnd.ms-project',
-            'xmpt' => 'application/vnd.ms-project',
-            'xmpy' => 'application/vnd.ibm.minipay',
-
-            'xmqy' => 'application/vnd.mobius.mqy',
-            'xmrc' => 'application/marc',
-            'xmscml' => 'application/mediaservercontrol+xml',
-            'xmseq' => 'application/vnd.mseq',
-            'xmsf' => 'application/vnd.epson.msf',
-            'xmsh' => 'model/mesh',
-            'xmsi' => 'application/x-msdownload',
-            'xmsl' => 'application/vnd.mobius.msl',
-            'xmsty' => 'application/vnd.muvee.style',
-
-            'xmts' => 'model/vnd.mts',
-            'xmus' => 'application/vnd.musician',
-            'xmvb' => 'application/x-msmediaview',
-            'xmwf' => 'application/vnd.mfer',
-            'xmxf' => 'application/mxf',
-            'xmxl' => 'application/vnd.recordare.musicxml',
-            'xmxml' => 'application/xv+xml',
-            'xmxs' => 'application/vnd.triscape.mxs',
-            'xmxu' => 'video/vnd.mpegurl',
-
-            'xn-gage' => 'application/vnd.nokia.n-gage.symbian.install',
-            'xngdat' => 'application/vnd.nokia.n-gage.data',
-            'xnlu' => 'application/vnd.neurolanguage.nlu',
-            'xnml' => 'application/vnd.enliven',
-            'xnnd' => 'application/vnd.noblenet-directory',
-            'xnns' => 'application/vnd.noblenet-sealer',
-            'xnnw' => 'application/vnd.noblenet-web',
-            'xnpx' => 'image/vnd.net-fpx',
-            'xnsf' => 'application/vnd.lotus-notes',
-
-            'xoa2' => 'application/vnd.fujitsu.oasys2',
-            'xoa3' => 'application/vnd.fujitsu.oasys3',
-            'xoas' => 'application/vnd.fujitsu.oasys',
-            'xobd' => 'application/x-msbinder',
-            'xoda' => 'application/oda',
-            'xodc' => 'application/vnd.oasis.opendocument.chart',
-            'xodf' => 'application/vnd.oasis.opendocument.formula',
-            'xodg' => 'application/vnd.oasis.opendocument.graphics',
-            'xodi' => 'application/vnd.oasis.opendocument.image',
-
-            'xodp' => 'application/vnd.oasis.opendocument.presentation',
-            'xods' => 'application/vnd.oasis.opendocument.spreadsheet',
-            'xodt' => 'application/vnd.oasis.opendocument.text',
-            'xogg' => 'application/ogg',
-            'xoprc' => 'application/vnd.palm',
-            'xorg' => 'application/vnd.lotus-organizer',
-            'xotc' => 'application/vnd.oasis.opendocument.chart-template',
-            'xotf' => 'application/vnd.oasis.opendocument.formula-template',
-            'xotg' => 'application/vnd.oasis.opendocument.graphics-template',
-
-            'xoth' => 'application/vnd.oasis.opendocument.text-web',
-            'xoti' => 'application/vnd.oasis.opendocument.image-template',
-            'xotm' => 'application/vnd.oasis.opendocument.text-master',
-            'xots' => 'application/vnd.oasis.opendocument.spreadsheet-template',
-            'xott' => 'application/vnd.oasis.opendocument.text-template',
-            'xoxt' => 'application/vnd.openofficeorg.extension',
-            'xp10' => 'application/pkcs10',
-            'xp7r' => 'application/x-pkcs7-certreqresp',
-            'xp7s' => 'application/pkcs7-signature',
-
-            'xpbd' => 'application/vnd.powerbuilder6',
-            'xpbm' => 'image/x-portable-bitmap',
-            'xpcl' => 'application/vnd.hp-pcl',
-            'xpclxl' => 'application/vnd.hp-pclxl',
-            'xpct' => 'image/x-pict',
-            'xpcx' => 'image/x-pcx',
-            'xpdb' => 'chemical/x-pdb',
-            'xpdf' => 'application/pdf',
-            'xpfr' => 'application/font-tdpfr',
-
-            'xpgm' => 'image/x-portable-graymap',
-            'xpgn' => 'application/x-chess-pgn',
-            'xpgp' => 'application/pgp-encrypted',
-            'xpic' => 'image/x-pict',
-            'xpki' => 'application/pkixcmp',
-            'xpkipath' => 'application/pkix-pkipath',
-            'xplb' => 'application/vnd.3gpp.pic-bw-large',
-            'xplc' => 'application/vnd.mobius.plc',
-            'xplf' => 'application/vnd.pocketlearn',
-
-            'xpls' => 'application/pls+xml',
-            'xpml' => 'application/vnd.ctc-posml',
-            'xpng' => 'image/png',
-            'xpnm' => 'image/x-portable-anymap',
-            'xportpkg' => 'application/vnd.macports.portpkg',
-            'xpot' => 'application/vnd.ms-powerpoint',
-            'xppd' => 'application/vnd.cups-ppd',
-            'xppm' => 'image/x-portable-pixmap',
-            'xpps' => 'application/vnd.ms-powerpoint',
-
-            'xppt' => 'application/vnd.ms-powerpoint',
-            'xpqa' => 'application/vnd.palm',
-            'xprc' => 'application/vnd.palm',
-            'xpre' => 'application/vnd.lotus-freelance',
-            'xprf' => 'application/pics-rules',
-            'xps' => 'application/postscript',
-            'xpsb' => 'application/vnd.3gpp.pic-bw-small',
-            'xpsd' => 'image/vnd.adobe.photoshop',
-            'xptid' => 'application/vnd.pvi.ptid1',
-
-            'xpub' => 'application/x-mspublisher',
-            'xpvb' => 'application/vnd.3gpp.pic-bw-var',
-            'xpwn' => 'application/vnd.3m.post-it-notes',
-            'xqam' => 'application/vnd.epson.quickanime',
-            'xqbo' => 'application/vnd.intu.qbo',
-            'xqfx' => 'application/vnd.intu.qfx',
-            'xqps' => 'application/vnd.publishare-delta-tree',
-            'xqt' => 'video/quicktime',
-            'xra' => 'audio/x-pn-realaudio',
-
-            'xram' => 'audio/x-pn-realaudio',
-            'xrar' => 'application/x-rar-compressed',
-            'xras' => 'image/x-cmu-raster',
-            'xrcprofile' => 'application/vnd.ipunplugged.rcprofile',
-            'xrdf' => 'application/rdf+xml',
-            'xrdz' => 'application/vnd.data-vision.rdz',
-            'xrep' => 'application/vnd.businessobjects',
-            'xrgb' => 'image/x-rgb',
-            'xrif' => 'application/reginfo+xml',
-
-            'xrl' => 'application/resource-lists+xml',
-            'xrlc' => 'image/vnd.fujixerox.edmics-rlc',
-            'xrm' => 'application/vnd.rn-realmedia',
-            'xrmi' => 'audio/midi',
-            'xrmp' => 'audio/x-pn-realaudio-plugin',
-            'xrms' => 'application/vnd.jcp.javame.midlet-rms',
-            'xrnc' => 'application/relax-ng-compact-syntax',
-            'xrpss' => 'application/vnd.nokia.radio-presets',
-            'xrpst' => 'application/vnd.nokia.radio-preset',
-
-            'xrq' => 'application/sparql-query',
-            'xrs' => 'application/rls-services+xml',
-            'xrsd' => 'application/rsd+xml',
-            'xrss' => 'application/rss+xml',
-            'xrtf' => 'application/rtf',
-            'xrtx' => 'text/richtext',
-            'xsaf' => 'application/vnd.yamaha.smaf-audio',
-            'xsbml' => 'application/sbml+xml',
-            'xsc' => 'application/vnd.ibm.secure-container',
-
-            'xscd' => 'application/x-msschedule',
-            'xscm' => 'application/vnd.lotus-screencam',
-            'xscq' => 'application/scvp-cv-request',
-            'xscs' => 'application/scvp-cv-response',
-            'xsdp' => 'application/sdp',
-            'xsee' => 'application/vnd.seemail',
-            'xsema' => 'application/vnd.sema',
-            'xsemd' => 'application/vnd.semd',
-            'xsemf' => 'application/vnd.semf',
-
-            'xsetpay' => 'application/set-payment-initiation',
-            'xsetreg' => 'application/set-registration-initiation',
-            'xsfs' => 'application/vnd.spotfire.sfs',
-            'xsgm' => 'text/sgml',
-            'xsgml' => 'text/sgml',
-            'xsh' => 'application/x-sh',
-            'xshar' => 'application/x-shar',
-            'xshf' => 'application/shf+xml',
-            'xsilo' => 'model/mesh',
-
-            'xsit' => 'application/x-stuffit',
-            'xsitx' => 'application/x-stuffitx',
-            'xslt' => 'application/vnd.epson.salt',
-            'xsnd' => 'audio/basic',
-            'xspf' => 'application/vnd.yamaha.smaf-phrase',
-            'xspl' => 'application/x-futuresplash',
-            'xspot' => 'text/vnd.in3d.spot',
-            'xspp' => 'application/scvp-vp-response',
-            'xspq' => 'application/scvp-vp-request',
-
-            'xsrc' => 'application/x-wais-source',
-            'xsrx' => 'application/sparql-results+xml',
-            'xssf' => 'application/vnd.epson.ssf',
-            'xssml' => 'application/ssml+xml',
-            'xstf' => 'application/vnd.wt.stf',
-            'xstk' => 'application/hyperstudio',
-            'xstr' => 'application/vnd.pg.format',
-            'xsus' => 'application/vnd.sus-calendar',
-            'xsusp' => 'application/vnd.sus-calendar',
-
-            'xsv4cpio' => 'application/x-sv4cpio',
-            'xsv4crc' => 'application/x-sv4crc',
-            'xsvd' => 'application/vnd.svd',
-            'xswf' => 'application/x-shockwave-flash',
-            'xtao' => 'application/vnd.tao.intent-module-archive',
-            'xtar' => 'application/x-tar',
-            'xtcap' => 'application/vnd.3gpp2.tcap',
-            'xtcl' => 'application/x-tcl',
-            'xtex' => 'application/x-tex',
-
-            'xtext' => 'text/plain',
-            'xtif' => 'image/tiff',
-            'xtiff' => 'image/tiff',
-            'xtmo' => 'application/vnd.tmobile-livetv',
-            'xtorrent' => 'application/x-bittorrent',
-            'xtpl' => 'application/vnd.groove-tool-template',
-            'xtpt' => 'application/vnd.trid.tpt',
-            'xtra' => 'application/vnd.trueapp',
-            'xtrm' => 'application/x-msterminal',
-
-            'xtsv' => 'text/tab-separated-values',
-            'xtxd' => 'application/vnd.genomatix.tuxedo',
-            'xtxf' => 'application/vnd.mobius.txf',
-            'xtxt' => 'text/plain',
-            'xumj' => 'application/vnd.umajin',
-            'xunityweb' => 'application/vnd.unity',
-            'xuoml' => 'application/vnd.uoml+xml',
-            'xuri' => 'text/uri-list',
-            'xuris' => 'text/uri-list',
-
-            'xurls' => 'text/uri-list',
-            'xustar' => 'application/x-ustar',
-            'xutz' => 'application/vnd.uiq.theme',
-            'xuu' => 'text/x-uuencode',
-            'xvcd' => 'application/x-cdlink',
-            'xvcf' => 'text/x-vcard',
-            'xvcg' => 'application/vnd.groove-vcard',
-            'xvcs' => 'text/x-vcalendar',
-            'xvcx' => 'application/vnd.vcx',
-
-            'xvis' => 'application/vnd.visionary',
-            'xviv' => 'video/vnd.vivo',
-            'xvrml' => 'model/vrml',
-            'xvsd' => 'application/vnd.visio',
-            'xvsf' => 'application/vnd.vsf',
-            'xvss' => 'application/vnd.visio',
-            'xvst' => 'application/vnd.visio',
-            'xvsw' => 'application/vnd.visio',
-            'xvtu' => 'model/vnd.vtu',
-
-            'xvxml' => 'application/voicexml+xml',
-            'xwav' => 'audio/x-wav',
-            'xwax' => 'audio/x-ms-wax',
-            'xwbmp' => 'image/vnd.wap.wbmp',
-            'xwbs' => 'application/vnd.criticaltools.wbs+xml',
-            'xwbxml' => 'application/vnd.wap.wbxml',
-            'xwcm' => 'application/vnd.ms-works',
-            'xwdb' => 'application/vnd.ms-works',
-            'xwks' => 'application/vnd.ms-works',
-
-            'xwm' => 'video/x-ms-wm',
-            'xwma' => 'audio/x-ms-wma',
-            'xwmd' => 'application/x-ms-wmd',
-            'xwmf' => 'application/x-msmetafile',
-            'xwml' => 'text/vnd.wap.wml',
-            'xwmlc' => 'application/vnd.wap.wmlc',
-            'xwmls' => 'text/vnd.wap.wmlscript',
-            'xwmlsc' => 'application/vnd.wap.wmlscriptc',
-            'xwmv' => 'video/x-ms-wmv',
-
-            'xwmx' => 'video/x-ms-wmx',
-            'xwmz' => 'application/x-ms-wmz',
-            'xwpd' => 'application/vnd.wordperfect',
-            'xwpl' => 'application/vnd.ms-wpl',
-            'xwps' => 'application/vnd.ms-works',
-            'xwqd' => 'application/vnd.wqd',
-            'xwri' => 'application/x-mswrite',
-            'xwrl' => 'model/vrml',
-            'xwsdl' => 'application/wsdl+xml',
-
-            'xwspolicy' => 'application/wspolicy+xml',
-            'xwtb' => 'application/vnd.webturbo',
-            'xwvx' => 'video/x-ms-wvx',
-            'xx3d' => 'application/vnd.hzn-3d-crossword',
-            'xxar' => 'application/vnd.xara',
-            'xxbd' => 'application/vnd.fujixerox.docuworks.binder',
-            'xxbm' => 'image/x-xbitmap',
-            'xxdm' => 'application/vnd.syncml.dm+xml',
-            'xxdp' => 'application/vnd.adobe.xdp+xml',
-
-            'xxdw' => 'application/vnd.fujixerox.docuworks',
-            'xxenc' => 'application/xenc+xml',
-            'xxfdf' => 'application/vnd.adobe.xfdf',
-            'xxfdl' => 'application/vnd.xfdl',
-            'xxht' => 'application/xhtml+xml',
-            'xxhtml' => 'application/xhtml+xml',
-            'xxhvml' => 'application/xv+xml',
-            'xxif' => 'image/vnd.xiff',
-            'xxla' => 'application/vnd.ms-excel',
-
-            'xxlc' => 'application/vnd.ms-excel',
-            'xxlm' => 'application/vnd.ms-excel',
-            'xxls' => 'application/vnd.ms-excel',
-            'xxlt' => 'application/vnd.ms-excel',
-            'xxlw' => 'application/vnd.ms-excel',
-            'xxml' => 'application/xml',
-            'xxo' => 'application/vnd.olpc-sugar',
-            'xxop' => 'application/xop+xml',
-            'xxpm' => 'image/x-xpixmap',
-
-            'xxpr' => 'application/vnd.is-xpr',
-            'xxps' => 'application/vnd.ms-xpsdocument',
-            'xxsl' => 'application/xml',
-            'xxslt' => 'application/xslt+xml',
-            'xxsm' => 'application/vnd.syncml+xml',
-            'xxspf' => 'application/xspf+xml',
-            'xxul' => 'application/vnd.mozilla.xul+xml',
-            'xxvm' => 'application/xv+xml',
-            'xxvml' => 'application/xv+xml',
-
-            'xxwd' => 'image/x-xwindowdump',
-            'xxyz' => 'chemical/x-xyz',
-            'xzaz' => 'application/vnd.zzazz.deck+xml',
-            'xzip' => 'application/zip',
-            'xzmm' => 'application/vnd.handheld-entertainment+xml',
-            'xodt' => 'application/x-vnd.oasis.opendocument.spreadsheet'
-        );
 }
diff --git app/code/core/Mage/Oauth/Model/Server.php app/code/core/Mage/Oauth/Model/Server.php
index 6ae3a9f..4fc0d33 100644
--- app/code/core/Mage/Oauth/Model/Server.php
+++ app/code/core/Mage/Oauth/Model/Server.php
@@ -328,10 +328,10 @@ class Mage_Oauth_Model_Server
             if (self::REQUEST_TOKEN == $this->_requestType) {
                 $this->_validateVerifierParam();
 
-                if ($this->_token->getVerifier() != $this->_protocolParams['oauth_verifier']) {
+                if (!hash_equals($this->_token->getVerifier(), $this->_protocolParams['oauth_verifier'])) {
                     $this->_throwException('', self::ERR_VERIFIER_INVALID);
                 }
-                if ($this->_token->getConsumerId() != $this->_consumer->getId()) {
+                if (!hash_equals($this->_token->getConsumerId(), $this->_consumer->getId())) {
                     $this->_throwException('', self::ERR_TOKEN_REJECTED);
                 }
                 if (Mage_Oauth_Model_Token::TYPE_REQUEST != $this->_token->getType()) {
@@ -544,7 +544,7 @@ class Mage_Oauth_Model_Server
             $this->_request->getScheme() . '://' . $this->_request->getHttpHost() . $this->_request->getRequestUri()
         );
 
-        if ($calculatedSign != $this->_protocolParams['oauth_signature']) {
+        if (!hash_equals($calculatedSign, $this->_protocolParams['oauth_signature'])) {
             $this->_throwException('', self::ERR_SIGNATURE_INVALID);
         }
     }
diff --git app/code/core/Mage/Paygate/Model/Authorizenet.php app/code/core/Mage/Paygate/Model/Authorizenet.php
index 2c0be1e..3c3e0a0 100644
--- app/code/core/Mage/Paygate/Model/Authorizenet.php
+++ app/code/core/Mage/Paygate/Model/Authorizenet.php
@@ -1273,8 +1273,10 @@ class Mage_Paygate_Model_Authorizenet extends Mage_Payment_Model_Method_Cc
         $uri = $this->getConfigData('cgi_url');
         $client->setUri($uri ? $uri : self::CGI_URL);
         $client->setConfig(array(
-            'maxredirects'=>0,
-            'timeout'=>30,
+            'maxredirects' => 0,
+            'timeout' => 30,
+            'verifyhost' => 2,
+            'verifypeer' => true,
             //'ssltransport' => 'tcp',
         ));
         foreach ($request->getData() as $key => $value) {
@@ -1543,7 +1545,11 @@ class Mage_Paygate_Model_Authorizenet extends Mage_Payment_Model_Method_Cc
         $uri = $this->getConfigData('cgi_url_td');
         $uri = $uri ? $uri : self::CGI_URL_TD;
         $client->setUri($uri);
-        $client->setConfig(array('timeout'=>45));
+        $client->setConfig(array(
+            'timeout' => 45,
+            'verifyhost' => 2,
+            'verifypeer' => true,
+        ));
         $client->setHeaders(array('Content-Type: text/xml'));
         $client->setMethod(Zend_Http_Client::POST);
         $client->setRawData($requestBody);
diff --git app/code/core/Mage/Payment/Block/Info/Checkmo.php app/code/core/Mage/Payment/Block/Info/Checkmo.php
index 978c3d5..767b839 100644
--- app/code/core/Mage/Payment/Block/Info/Checkmo.php
+++ app/code/core/Mage/Payment/Block/Info/Checkmo.php
@@ -70,7 +70,13 @@ class Mage_Payment_Block_Info_Checkmo extends Mage_Payment_Block_Info
      */
     protected function _convertAdditionalData()
     {
-        $details = @unserialize($this->getInfo()->getAdditionalData());
+        $details = false;
+        try {
+            $details = Mage::helper('core/unserializeArray')
+                ->unserialize($this->getInfo()->getAdditionalData());
+        } catch (Exception $e) {
+            Mage::logException($e);
+        }
         if (is_array($details)) {
             $this->_payableTo = isset($details['payable_to']) ? (string) $details['payable_to'] : '';
             $this->_mailingAddress = isset($details['mailing_address']) ? (string) $details['mailing_address'] : '';
@@ -80,7 +86,7 @@ class Mage_Payment_Block_Info_Checkmo extends Mage_Payment_Block_Info
         }
         return $this;
     }
-    
+
     public function toPdf()
     {
         $this->setTemplate('payment/info/pdf/checkmo.phtml');
diff --git app/code/core/Mage/Paypal/Model/Express/Checkout.php app/code/core/Mage/Paypal/Model/Express/Checkout.php
index 6057892..9c1ad2f 100644
--- app/code/core/Mage/Paypal/Model/Express/Checkout.php
+++ app/code/core/Mage/Paypal/Model/Express/Checkout.php
@@ -947,7 +947,7 @@ class Mage_Paypal_Model_Express_Checkout
         $shipping   = $quote->isVirtual() ? null : $quote->getShippingAddress();
 
         $customerId = $this->_lookupCustomerId();
-        if ($customerId) {
+        if ($customerId && !$this->_customerEmailExists($quote->getCustomerEmail())) {
             $this->getCustomerSession()->loginById($customerId);
             return $this->_prepareCustomerQuote();
         }
@@ -1063,4 +1063,26 @@ class Mage_Paypal_Model_Express_Checkout
     {
         return $this->_customerSession;
     }
+
+    /**
+     * Check if customer email exists
+     *
+     * @param string $email
+     * @return bool
+     */
+    protected function _customerEmailExists($email)
+    {
+        $result    = false;
+        $customer  = Mage::getModel('customer/customer');
+        $websiteId = Mage::app()->getStore()->getWebsiteId();
+        if (!is_null($websiteId)) {
+            $customer->setWebsiteId($websiteId);
+        }
+        $customer->loadByEmail($email);
+        if (!is_null($customer->getId())) {
+            $result = true;
+        }
+
+        return $result;
+    }
 }
diff --git app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php
index e250599..ac5f9e3 100644
--- app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php
+++ app/code/core/Mage/Paypal/Model/Resource/Payment/Transaction.php
@@ -53,6 +53,30 @@ class Mage_Paypal_Model_Resource_Payment_Transaction extends Mage_Core_Model_Res
     }
 
     /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                    ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
+
+    /**
      * Load the transaction object by specified txn_id
      *
      * @param Mage_Paypal_Model_Payment_Transaction $transaction
diff --git app/code/core/Mage/Sales/Model/Resource/Order/Payment.php app/code/core/Mage/Sales/Model/Resource/Order/Payment.php
index c0ad392..d91ed86 100644
--- app/code/core/Mage/Sales/Model/Resource/Order/Payment.php
+++ app/code/core/Mage/Sales/Model/Resource/Order/Payment.php
@@ -58,4 +58,28 @@ class Mage_Sales_Model_Resource_Order_Payment extends Mage_Sales_Model_Resource_
     {
         $this->_init('sales/order_payment', 'entity_id');
     }
+
+    /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
 }
diff --git app/code/core/Mage/Sales/Model/Resource/Order/Payment/Transaction.php app/code/core/Mage/Sales/Model/Resource/Order/Payment/Transaction.php
index b6e8208..a66aa69 100644
--- app/code/core/Mage/Sales/Model/Resource/Order/Payment/Transaction.php
+++ app/code/core/Mage/Sales/Model/Resource/Order/Payment/Transaction.php
@@ -53,6 +53,30 @@ class Mage_Sales_Model_Resource_Order_Payment_Transaction extends Mage_Sales_Mod
     }
 
     /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
+
+    /**
      * Update transactions in database using provided transaction as parent for them
      * have to repeat the business logic to avoid accidental injection of wrong transactions
      *
diff --git app/code/core/Mage/Sales/Model/Resource/Quote/Payment.php app/code/core/Mage/Sales/Model/Resource/Quote/Payment.php
index 125b407..ffca9e5 100644
--- app/code/core/Mage/Sales/Model/Resource/Quote/Payment.php
+++ app/code/core/Mage/Sales/Model/Resource/Quote/Payment.php
@@ -51,4 +51,28 @@ class Mage_Sales_Model_Resource_Quote_Payment extends Mage_Sales_Model_Resource_
     {
         $this->_init('sales/quote_payment', 'payment_id');
     }
+
+    /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                    ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
 }
diff --git app/code/core/Mage/Sales/Model/Resource/Recurring/Profile.php app/code/core/Mage/Sales/Model/Resource/Recurring/Profile.php
index 06bc71d..4702e53 100644
--- app/code/core/Mage/Sales/Model/Resource/Recurring/Profile.php
+++ app/code/core/Mage/Sales/Model/Resource/Recurring/Profile.php
@@ -54,6 +54,33 @@ class Mage_Sales_Model_Resource_Recurring_Profile extends Mage_Sales_Model_Resou
     }
 
     /**
+     * Unserialize Varien_Object field in an object
+     *
+     * @param Mage_Core_Model_Abstract $object
+     * @param string $field
+     * @param mixed $defaultValue
+     */
+    protected function _unserializeField(Varien_Object $object, $field, $defaultValue = null)
+    {
+        if ($field != 'additional_info') {
+            return parent::_unserializeField($object, $field, $defaultValue);
+        }
+        $value = $object->getData($field);
+        if (empty($value)) {
+            $object->setData($field, $defaultValue);
+        } elseif (!is_array($value) && !is_object($value)) {
+            $unserializedValue = false;
+            try {
+                $unserializedValue = Mage::helper('core/unserializeArray')
+                ->unserialize($value);
+            } catch (Exception $e) {
+                Mage::logException($e);
+            }
+            $object->setData($field, $unserializedValue);
+        }
+    }
+
+    /**
      * Return recurring profile child Orders Ids
      *
      *
diff --git app/code/core/Mage/Uploader/Block/Abstract.php app/code/core/Mage/Uploader/Block/Abstract.php
new file mode 100644
index 0000000..0cba674
--- /dev/null
+++ app/code/core/Mage/Uploader/Block/Abstract.php
@@ -0,0 +1,247 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+abstract class Mage_Uploader_Block_Abstract extends Mage_Adminhtml_Block_Widget
+{
+    /**
+     * Template used for uploader
+     *
+     * @var string
+     */
+    protected $_template = 'media/uploader.phtml';
+
+    /**
+     * @var Mage_Uploader_Model_Config_Misc
+     */
+    protected $_misc;
+
+    /**
+     * @var Mage_Uploader_Model_Config_Uploader
+     */
+    protected $_uploaderConfig;
+
+    /**
+     * @var Mage_Uploader_Model_Config_Browsebutton
+     */
+    protected $_browseButtonConfig;
+
+    /**
+     * @var Mage_Uploader_Model_Config_Misc
+     */
+    protected $_miscConfig;
+
+    /**
+     * @var array
+     */
+    protected $_idsMapping = array();
+
+    /**
+     * Default browse button ID suffix
+     */
+    const DEFAULT_BROWSE_BUTTON_ID_SUFFIX = 'browse';
+
+    /**
+     * Constructor for uploader block
+     *
+     * @see https://github.com/flowjs/flow.js/tree/v2.9.0#configuration
+     * @description Set unique id for block
+     */
+    public function __construct()
+    {
+        parent::__construct();
+        $this->setId($this->getId() . '_Uploader');
+    }
+
+    /**
+     * Helper for file manipulation
+     *
+     * @return Mage_Uploader_Helper_File
+     */
+    protected function _getHelper()
+    {
+        return Mage::helper('uploader/file');
+    }
+
+    /**
+     * @return string
+     */
+    public function getJsonConfig()
+    {
+        return $this->helper('core')->jsonEncode(array(
+            'uploaderConfig'    => $this->getUploaderConfig()->getData(),
+            'elementIds'        => $this->_getElementIdsMapping(),
+            'browseConfig'      => $this->getButtonConfig()->getData(),
+            'miscConfig'        => $this->getMiscConfig()->getData(),
+        ));
+    }
+
+    /**
+     * Get mapping of ids for front-end use
+     *
+     * @return array
+     */
+    protected function _getElementIdsMapping()
+    {
+        return $this->_idsMapping;
+    }
+
+    /**
+     * Add mapping ids for front-end use
+     *
+     * @param array $additionalButtons
+     * @return $this
+     */
+    protected function _addElementIdsMapping($additionalButtons = array())
+    {
+        $this->_idsMapping = array_merge($this->_idsMapping, $additionalButtons);
+
+        return $this;
+    }
+
+    /**
+     * Prepare layout, create buttons, set front-end elements ids
+     *
+     * @return Mage_Core_Block_Abstract
+     */
+    protected function _prepareLayout()
+    {
+        $this->setChild(
+            'browse_button',
+            $this->getLayout()->createBlock('adminhtml/widget_button')
+                ->addData(array(
+                    // Workaround for IE9
+                    'before_html'   => sprintf(
+                        '<div style="display:inline-block;" id="%s">',
+                        $this->getElementId(self::DEFAULT_BROWSE_BUTTON_ID_SUFFIX)
+                    ),
+                    'after_html'    => '</div>',
+                    'id'            => $this->getElementId(self::DEFAULT_BROWSE_BUTTON_ID_SUFFIX . '_button'),
+                    'label'         => Mage::helper('uploader')->__('Browse Files...'),
+                    'type'          => 'button',
+                ))
+        );
+
+        $this->setChild(
+            'delete_button',
+            $this->getLayout()->createBlock('adminhtml/widget_button')
+                ->addData(array(
+                    'id'      => '{{id}}',
+                    'class'   => 'delete',
+                    'type'    => 'button',
+                    'label'   => Mage::helper('uploader')->__('Remove')
+                ))
+        );
+
+        $this->_addElementIdsMapping(array(
+            'container'         => $this->getHtmlId(),
+            'templateFile'      => $this->getElementId('template'),
+            'browse'            => $this->_prepareElementsIds(array(self::DEFAULT_BROWSE_BUTTON_ID_SUFFIX))
+        ));
+
+        return parent::_prepareLayout();
+    }
+
+    /**
+     * Get browse button html
+     *
+     * @return string
+     */
+    public function getBrowseButtonHtml()
+    {
+        return $this->getChildHtml('browse_button');
+    }
+
+    /**
+     * Get delete button html
+     *
+     * @return string
+     */
+    public function getDeleteButtonHtml()
+    {
+        return $this->getChildHtml('delete_button');
+    }
+
+    /**
+     * Get uploader misc settings
+     *
+     * @return Mage_Uploader_Model_Config_Misc
+     */
+    public function getMiscConfig()
+    {
+        if (is_null($this->_miscConfig)) {
+            $this->_miscConfig = Mage::getModel('uploader/config_misc');
+        }
+        return $this->_miscConfig;
+    }
+
+    /**
+     * Get uploader general settings
+     *
+     * @return Mage_Uploader_Model_Config_Uploader
+     */
+    public function getUploaderConfig()
+    {
+        if (is_null($this->_uploaderConfig)) {
+            $this->_uploaderConfig = Mage::getModel('uploader/config_uploader');
+        }
+        return $this->_uploaderConfig;
+    }
+
+    /**
+     * Get browse button settings
+     *
+     * @return Mage_Uploader_Model_Config_Browsebutton
+     */
+    public function getButtonConfig()
+    {
+        if (is_null($this->_browseButtonConfig)) {
+            $this->_browseButtonConfig = Mage::getModel('uploader/config_browsebutton');
+        }
+        return $this->_browseButtonConfig;
+    }
+
+    /**
+     * Get button unique id
+     *
+     * @param string $suffix
+     * @return string
+     */
+    public function getElementId($suffix)
+    {
+        return $this->getHtmlId() . '-' . $suffix;
+    }
+
+    /**
+     * Prepare actual elements ids from suffixes
+     *
+     * @param array $targets $type => array($idsSuffixes)
+     * @return array $type => array($htmlIds)
+     */
+    protected function _prepareElementsIds($targets)
+    {
+        return array_map(array($this, 'getElementId'), array_unique(array_values($targets)));
+    }
+}
diff --git app/code/core/Mage/Uploader/Block/Multiple.php app/code/core/Mage/Uploader/Block/Multiple.php
new file mode 100644
index 0000000..923f045
--- /dev/null
+++ app/code/core/Mage/Uploader/Block/Multiple.php
@@ -0,0 +1,71 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+class Mage_Uploader_Block_Multiple extends Mage_Uploader_Block_Abstract
+{
+    /**
+     *
+     * Default upload button ID suffix
+     */
+    const DEFAULT_UPLOAD_BUTTON_ID_SUFFIX = 'upload';
+
+
+    /**
+     * Prepare layout, create upload button
+     *
+     * @return Mage_Uploader_Block_Multiple
+     */
+    protected function _prepareLayout()
+    {
+        parent::_prepareLayout();
+
+        $this->setChild(
+            'upload_button',
+            $this->getLayout()->createBlock('adminhtml/widget_button')
+                ->addData(array(
+                    'id'      => $this->getElementId(self::DEFAULT_UPLOAD_BUTTON_ID_SUFFIX),
+                    'label'   => Mage::helper('uploader')->__('Upload Files'),
+                    'type'    => 'button',
+                ))
+        );
+
+        $this->_addElementIdsMapping(array(
+            'upload' => $this->_prepareElementsIds(array(self::DEFAULT_UPLOAD_BUTTON_ID_SUFFIX))
+        ));
+
+        return $this;
+    }
+
+    /**
+     * Get upload button html
+     *
+     * @return string
+     */
+    public function getUploadButtonHtml()
+    {
+        return $this->getChildHtml('upload_button');
+    }
+}
diff --git app/code/core/Mage/Uploader/Block/Single.php app/code/core/Mage/Uploader/Block/Single.php
new file mode 100644
index 0000000..4ce4663
--- /dev/null
+++ app/code/core/Mage/Uploader/Block/Single.php
@@ -0,0 +1,52 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+class Mage_Uploader_Block_Single extends Mage_Uploader_Block_Abstract
+{
+    /**
+     * Prepare layout, change button and set front-end element ids mapping
+     *
+     * @return Mage_Core_Block_Abstract
+     */
+    protected function _prepareLayout()
+    {
+        parent::_prepareLayout();
+        $this->getChild('browse_button')->setLabel(Mage::helper('uploader')->__('...'));
+
+        return $this;
+    }
+
+    /**
+     * Constructor for single uploader block
+     */
+    public function __construct()
+    {
+        parent::__construct();
+
+        $this->getUploaderConfig()->setSingleFile(true);
+        $this->getButtonConfig()->setSingleFile(true);
+    }
+}
diff --git app/code/core/Mage/Uploader/Helper/Data.php app/code/core/Mage/Uploader/Helper/Data.php
new file mode 100644
index 0000000..c260604
--- /dev/null
+++ app/code/core/Mage/Uploader/Helper/Data.php
@@ -0,0 +1,30 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+class Mage_Uploader_Helper_Data extends Mage_Core_Helper_Abstract
+{
+
+}
diff --git app/code/core/Mage/Uploader/Helper/File.php app/code/core/Mage/Uploader/Helper/File.php
new file mode 100644
index 0000000..9685a03
--- /dev/null
+++ app/code/core/Mage/Uploader/Helper/File.php
@@ -0,0 +1,750 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+class Mage_Uploader_Helper_File extends Mage_Core_Helper_Abstract
+{
+    /**
+     * List of pre-defined MIME types
+     *
+     * @var array
+     */
+    protected $_mimeTypes =
+        array(
+            'x123' => 'application/vnd.lotus-1-2-3',
+            'x3dml' => 'text/vnd.in3d.3dml',
+            'x3g2' => 'video/3gpp2',
+            'x3gp' => 'video/3gpp',
+            'xace' => 'application/x-ace-compressed',
+            'xacu' => 'application/vnd.acucobol',
+            'xaep' => 'application/vnd.audiograph',
+            'xai' => 'application/postscript',
+            'xaif' => 'audio/x-aiff',
+
+            'xaifc' => 'audio/x-aiff',
+            'xaiff' => 'audio/x-aiff',
+            'xami' => 'application/vnd.amiga.ami',
+            'xapr' => 'application/vnd.lotus-approach',
+            'xasf' => 'video/x-ms-asf',
+            'xaso' => 'application/vnd.accpac.simply.aso',
+            'xasx' => 'video/x-ms-asf',
+            'xatom' => 'application/atom+xml',
+            'xatomcat' => 'application/atomcat+xml',
+
+            'xatomsvc' => 'application/atomsvc+xml',
+            'xatx' => 'application/vnd.antix.game-component',
+            'xau' => 'audio/basic',
+            'xavi' => 'video/x-msvideo',
+            'xbat' => 'application/x-msdownload',
+            'xbcpio' => 'application/x-bcpio',
+            'xbdm' => 'application/vnd.syncml.dm+wbxml',
+            'xbh2' => 'application/vnd.fujitsu.oasysprs',
+            'xbmi' => 'application/vnd.bmi',
+
+            'xbmp' => 'image/bmp',
+            'xbox' => 'application/vnd.previewsystems.box',
+            'xboz' => 'application/x-bzip2',
+            'xbtif' => 'image/prs.btif',
+            'xbz' => 'application/x-bzip',
+            'xbz2' => 'application/x-bzip2',
+            'xcab' => 'application/vnd.ms-cab-compressed',
+            'xccxml' => 'application/ccxml+xml',
+            'xcdbcmsg' => 'application/vnd.contact.cmsg',
+
+            'xcdkey' => 'application/vnd.mediastation.cdkey',
+            'xcdx' => 'chemical/x-cdx',
+            'xcdxml' => 'application/vnd.chemdraw+xml',
+            'xcdy' => 'application/vnd.cinderella',
+            'xcer' => 'application/pkix-cert',
+            'xcgm' => 'image/cgm',
+            'xchat' => 'application/x-chat',
+            'xchm' => 'application/vnd.ms-htmlhelp',
+            'xchrt' => 'application/vnd.kde.kchart',
+
+            'xcif' => 'chemical/x-cif',
+            'xcii' => 'application/vnd.anser-web-certificate-issue-initiation',
+            'xcil' => 'application/vnd.ms-artgalry',
+            'xcla' => 'application/vnd.claymore',
+            'xclkk' => 'application/vnd.crick.clicker.keyboard',
+            'xclkp' => 'application/vnd.crick.clicker.palette',
+            'xclkt' => 'application/vnd.crick.clicker.template',
+            'xclkw' => 'application/vnd.crick.clicker.wordbank',
+            'xclkx' => 'application/vnd.crick.clicker',
+
+            'xclp' => 'application/x-msclip',
+            'xcmc' => 'application/vnd.cosmocaller',
+            'xcmdf' => 'chemical/x-cmdf',
+            'xcml' => 'chemical/x-cml',
+            'xcmp' => 'application/vnd.yellowriver-custom-menu',
+            'xcmx' => 'image/x-cmx',
+            'xcom' => 'application/x-msdownload',
+            'xconf' => 'text/plain',
+            'xcpio' => 'application/x-cpio',
+
+            'xcpt' => 'application/mac-compactpro',
+            'xcrd' => 'application/x-mscardfile',
+            'xcrl' => 'application/pkix-crl',
+            'xcrt' => 'application/x-x509-ca-cert',
+            'xcsh' => 'application/x-csh',
+            'xcsml' => 'chemical/x-csml',
+            'xcss' => 'text/css',
+            'xcsv' => 'text/csv',
+            'xcurl' => 'application/vnd.curl',
+
+            'xcww' => 'application/prs.cww',
+            'xdaf' => 'application/vnd.mobius.daf',
+            'xdavmount' => 'application/davmount+xml',
+            'xdd2' => 'application/vnd.oma.dd2+xml',
+            'xddd' => 'application/vnd.fujixerox.ddd',
+            'xdef' => 'text/plain',
+            'xder' => 'application/x-x509-ca-cert',
+            'xdfac' => 'application/vnd.dreamfactory',
+            'xdis' => 'application/vnd.mobius.dis',
+
+            'xdjv' => 'image/vnd.djvu',
+            'xdjvu' => 'image/vnd.djvu',
+            'xdll' => 'application/x-msdownload',
+            'xdna' => 'application/vnd.dna',
+            'xdoc' => 'application/msword',
+            'xdot' => 'application/msword',
+            'xdp' => 'application/vnd.osgi.dp',
+            'xdpg' => 'application/vnd.dpgraph',
+            'xdsc' => 'text/prs.lines.tag',
+
+            'xdtd' => 'application/xml-dtd',
+            'xdvi' => 'application/x-dvi',
+            'xdwf' => 'model/vnd.dwf',
+            'xdwg' => 'image/vnd.dwg',
+            'xdxf' => 'image/vnd.dxf',
+            'xdxp' => 'application/vnd.spotfire.dxp',
+            'xecelp4800' => 'audio/vnd.nuera.ecelp4800',
+            'xecelp7470' => 'audio/vnd.nuera.ecelp7470',
+            'xecelp9600' => 'audio/vnd.nuera.ecelp9600',
+
+            'xecma' => 'application/ecmascript',
+            'xedm' => 'application/vnd.novadigm.edm',
+            'xedx' => 'application/vnd.novadigm.edx',
+            'xefif' => 'application/vnd.picsel',
+            'xei6' => 'application/vnd.pg.osasli',
+            'xeml' => 'message/rfc822',
+            'xeol' => 'audio/vnd.digital-winds',
+            'xeot' => 'application/vnd.ms-fontobject',
+            'xeps' => 'application/postscript',
+
+            'xesf' => 'application/vnd.epson.esf',
+            'xetx' => 'text/x-setext',
+            'xexe' => 'application/x-msdownload',
+            'xext' => 'application/vnd.novadigm.ext',
+            'xez' => 'application/andrew-inset',
+            'xez2' => 'application/vnd.ezpix-album',
+            'xez3' => 'application/vnd.ezpix-package',
+            'xfbs' => 'image/vnd.fastbidsheet',
+            'xfdf' => 'application/vnd.fdf',
+
+            'xfe_launch' => 'application/vnd.denovo.fcselayout-link',
+            'xfg5' => 'application/vnd.fujitsu.oasysgp',
+            'xfli' => 'video/x-fli',
+            'xflo' => 'application/vnd.micrografx.flo',
+            'xflw' => 'application/vnd.kde.kivio',
+            'xflx' => 'text/vnd.fmi.flexstor',
+            'xfly' => 'text/vnd.fly',
+            'xfnc' => 'application/vnd.frogans.fnc',
+            'xfpx' => 'image/vnd.fpx',
+
+            'xfsc' => 'application/vnd.fsc.weblaunch',
+            'xfst' => 'image/vnd.fst',
+            'xftc' => 'application/vnd.fluxtime.clip',
+            'xfti' => 'application/vnd.anser-web-funds-transfer-initiation',
+            'xfvt' => 'video/vnd.fvt',
+            'xfzs' => 'application/vnd.fuzzysheet',
+            'xg3' => 'image/g3fax',
+            'xgac' => 'application/vnd.groove-account',
+            'xgdl' => 'model/vnd.gdl',
+
+            'xghf' => 'application/vnd.groove-help',
+            'xgif' => 'image/gif',
+            'xgim' => 'application/vnd.groove-identity-message',
+            'xgph' => 'application/vnd.flographit',
+            'xgram' => 'application/srgs',
+            'xgrv' => 'application/vnd.groove-injector',
+            'xgrxml' => 'application/srgs+xml',
+            'xgtar' => 'application/x-gtar',
+            'xgtm' => 'application/vnd.groove-tool-message',
+
+            'xsvg' => 'image/svg+xml',
+
+            'xgtw' => 'model/vnd.gtw',
+            'xh261' => 'video/h261',
+            'xh263' => 'video/h263',
+            'xh264' => 'video/h264',
+            'xhbci' => 'application/vnd.hbci',
+            'xhdf' => 'application/x-hdf',
+            'xhlp' => 'application/winhlp',
+            'xhpgl' => 'application/vnd.hp-hpgl',
+            'xhpid' => 'application/vnd.hp-hpid',
+
+            'xhps' => 'application/vnd.hp-hps',
+            'xhqx' => 'application/mac-binhex40',
+            'xhtke' => 'application/vnd.kenameaapp',
+            'xhtm' => 'text/html',
+            'xhtml' => 'text/html',
+            'xhvd' => 'application/vnd.yamaha.hv-dic',
+            'xhvp' => 'application/vnd.yamaha.hv-voice',
+            'xhvs' => 'application/vnd.yamaha.hv-script',
+            'xice' => '#x-conference/x-cooltalk',
+
+            'xico' => 'image/x-icon',
+            'xics' => 'text/calendar',
+            'xief' => 'image/ief',
+            'xifb' => 'text/calendar',
+            'xifm' => 'application/vnd.shana.informed.formdata',
+            'xigl' => 'application/vnd.igloader',
+            'xigx' => 'application/vnd.micrografx.igx',
+            'xiif' => 'application/vnd.shana.informed.interchange',
+            'ximp' => 'application/vnd.accpac.simply.imp',
+
+            'xims' => 'application/vnd.ms-ims',
+            'xin' => 'text/plain',
+            'xipk' => 'application/vnd.shana.informed.package',
+            'xirm' => 'application/vnd.ibm.rights-management',
+            'xirp' => 'application/vnd.irepository.package+xml',
+            'xitp' => 'application/vnd.shana.informed.formtemplate',
+            'xivp' => 'application/vnd.immervision-ivp',
+            'xivu' => 'application/vnd.immervision-ivu',
+            'xjad' => 'text/vnd.sun.j2me.app-descriptor',
+
+            'xjam' => 'application/vnd.jam',
+            'xjava' => 'text/x-java-source',
+            'xjisp' => 'application/vnd.jisp',
+            'xjlt' => 'application/vnd.hp-jlyt',
+            'xjoda' => 'application/vnd.joost.joda-archive',
+            'xjpe' => 'image/jpeg',
+            'xjpeg' => 'image/jpeg',
+            'xjpg' => 'image/jpeg',
+            'xjpgm' => 'video/jpm',
+
+            'xjpgv' => 'video/jpeg',
+            'xjpm' => 'video/jpm',
+            'xjs' => 'application/javascript',
+            'xjson' => 'application/json',
+            'xkar' => 'audio/midi',
+            'xkarbon' => 'application/vnd.kde.karbon',
+            'xkfo' => 'application/vnd.kde.kformula',
+            'xkia' => 'application/vnd.kidspiration',
+            'xkml' => 'application/vnd.google-earth.kml+xml',
+
+            'xkmz' => 'application/vnd.google-earth.kmz',
+            'xkon' => 'application/vnd.kde.kontour',
+            'xksp' => 'application/vnd.kde.kspread',
+            'xlatex' => 'application/x-latex',
+            'xlbd' => 'application/vnd.llamagraphics.life-balance.desktop',
+            'xlbe' => 'application/vnd.llamagraphics.life-balance.exchange+xml',
+            'xles' => 'application/vnd.hhe.lesson-player',
+            'xlist' => 'text/plain',
+            'xlog' => 'text/plain',
+
+            'xlrm' => 'application/vnd.ms-lrm',
+            'xltf' => 'application/vnd.frogans.ltf',
+            'xlvp' => 'audio/vnd.lucent.voice',
+            'xlwp' => 'application/vnd.lotus-wordpro',
+            'xm13' => 'application/x-msmediaview',
+            'xm14' => 'application/x-msmediaview',
+            'xm1v' => 'video/mpeg',
+            'xm2a' => 'audio/mpeg',
+            'xm3a' => 'audio/mpeg',
+
+            'xm3u' => 'audio/x-mpegurl',
+            'xm4u' => 'video/vnd.mpegurl',
+            'xmag' => 'application/vnd.ecowin.chart',
+            'xmathml' => 'application/mathml+xml',
+            'xmbk' => 'application/vnd.mobius.mbk',
+            'xmbox' => 'application/mbox',
+            'xmc1' => 'application/vnd.medcalcdata',
+            'xmcd' => 'application/vnd.mcd',
+            'xmdb' => 'application/x-msaccess',
+
+            'xmdi' => 'image/vnd.ms-modi',
+            'xmesh' => 'model/mesh',
+            'xmfm' => 'application/vnd.mfmp',
+            'xmgz' => 'application/vnd.proteus.magazine',
+            'xmid' => 'audio/midi',
+            'xmidi' => 'audio/midi',
+            'xmif' => 'application/vnd.mif',
+            'xmime' => 'message/rfc822',
+            'xmj2' => 'video/mj2',
+
+            'xmjp2' => 'video/mj2',
+            'xmlp' => 'application/vnd.dolby.mlp',
+            'xmmd' => 'application/vnd.chipnuts.karaoke-mmd',
+            'xmmf' => 'application/vnd.smaf',
+            'xmmr' => 'image/vnd.fujixerox.edmics-mmr',
+            'xmny' => 'application/x-msmoney',
+            'xmov' => 'video/quicktime',
+            'xmovie' => 'video/x-sgi-movie',
+            'xmp2' => 'audio/mpeg',
+
+            'xmp2a' => 'audio/mpeg',
+            'xmp3' => 'audio/mpeg',
+            'xmp4' => 'video/mp4',
+            'xmp4a' => 'audio/mp4',
+            'xmp4s' => 'application/mp4',
+            'xmp4v' => 'video/mp4',
+            'xmpc' => 'application/vnd.mophun.certificate',
+            'xmpe' => 'video/mpeg',
+            'xmpeg' => 'video/mpeg',
+
+            'xmpg' => 'video/mpeg',
+            'xmpg4' => 'video/mp4',
+            'xmpga' => 'audio/mpeg',
+            'xmpkg' => 'application/vnd.apple.installer+xml',
+            'xmpm' => 'application/vnd.blueice.multipass',
+            'xmpn' => 'application/vnd.mophun.application',
+            'xmpp' => 'application/vnd.ms-project',
+            'xmpt' => 'application/vnd.ms-project',
+            'xmpy' => 'application/vnd.ibm.minipay',
+
+            'xmqy' => 'application/vnd.mobius.mqy',
+            'xmrc' => 'application/marc',
+            'xmscml' => 'application/mediaservercontrol+xml',
+            'xmseq' => 'application/vnd.mseq',
+            'xmsf' => 'application/vnd.epson.msf',
+            'xmsh' => 'model/mesh',
+            'xmsi' => 'application/x-msdownload',
+            'xmsl' => 'application/vnd.mobius.msl',
+            'xmsty' => 'application/vnd.muvee.style',
+
+            'xmts' => 'model/vnd.mts',
+            'xmus' => 'application/vnd.musician',
+            'xmvb' => 'application/x-msmediaview',
+            'xmwf' => 'application/vnd.mfer',
+            'xmxf' => 'application/mxf',
+            'xmxl' => 'application/vnd.recordare.musicxml',
+            'xmxml' => 'application/xv+xml',
+            'xmxs' => 'application/vnd.triscape.mxs',
+            'xmxu' => 'video/vnd.mpegurl',
+
+            'xn-gage' => 'application/vnd.nokia.n-gage.symbian.install',
+            'xngdat' => 'application/vnd.nokia.n-gage.data',
+            'xnlu' => 'application/vnd.neurolanguage.nlu',
+            'xnml' => 'application/vnd.enliven',
+            'xnnd' => 'application/vnd.noblenet-directory',
+            'xnns' => 'application/vnd.noblenet-sealer',
+            'xnnw' => 'application/vnd.noblenet-web',
+            'xnpx' => 'image/vnd.net-fpx',
+            'xnsf' => 'application/vnd.lotus-notes',
+
+            'xoa2' => 'application/vnd.fujitsu.oasys2',
+            'xoa3' => 'application/vnd.fujitsu.oasys3',
+            'xoas' => 'application/vnd.fujitsu.oasys',
+            'xobd' => 'application/x-msbinder',
+            'xoda' => 'application/oda',
+            'xodc' => 'application/vnd.oasis.opendocument.chart',
+            'xodf' => 'application/vnd.oasis.opendocument.formula',
+            'xodg' => 'application/vnd.oasis.opendocument.graphics',
+            'xodi' => 'application/vnd.oasis.opendocument.image',
+
+            'xodp' => 'application/vnd.oasis.opendocument.presentation',
+            'xods' => 'application/vnd.oasis.opendocument.spreadsheet',
+            'xodt' => 'application/vnd.oasis.opendocument.text',
+            'xogg' => 'application/ogg',
+            'xoprc' => 'application/vnd.palm',
+            'xorg' => 'application/vnd.lotus-organizer',
+            'xotc' => 'application/vnd.oasis.opendocument.chart-template',
+            'xotf' => 'application/vnd.oasis.opendocument.formula-template',
+            'xotg' => 'application/vnd.oasis.opendocument.graphics-template',
+
+            'xoth' => 'application/vnd.oasis.opendocument.text-web',
+            'xoti' => 'application/vnd.oasis.opendocument.image-template',
+            'xotm' => 'application/vnd.oasis.opendocument.text-master',
+            'xots' => 'application/vnd.oasis.opendocument.spreadsheet-template',
+            'xott' => 'application/vnd.oasis.opendocument.text-template',
+            'xoxt' => 'application/vnd.openofficeorg.extension',
+            'xp10' => 'application/pkcs10',
+            'xp7r' => 'application/x-pkcs7-certreqresp',
+            'xp7s' => 'application/pkcs7-signature',
+
+            'xpbd' => 'application/vnd.powerbuilder6',
+            'xpbm' => 'image/x-portable-bitmap',
+            'xpcl' => 'application/vnd.hp-pcl',
+            'xpclxl' => 'application/vnd.hp-pclxl',
+            'xpct' => 'image/x-pict',
+            'xpcx' => 'image/x-pcx',
+            'xpdb' => 'chemical/x-pdb',
+            'xpdf' => 'application/pdf',
+            'xpfr' => 'application/font-tdpfr',
+
+            'xpgm' => 'image/x-portable-graymap',
+            'xpgn' => 'application/x-chess-pgn',
+            'xpgp' => 'application/pgp-encrypted',
+            'xpic' => 'image/x-pict',
+            'xpki' => 'application/pkixcmp',
+            'xpkipath' => 'application/pkix-pkipath',
+            'xplb' => 'application/vnd.3gpp.pic-bw-large',
+            'xplc' => 'application/vnd.mobius.plc',
+            'xplf' => 'application/vnd.pocketlearn',
+
+            'xpls' => 'application/pls+xml',
+            'xpml' => 'application/vnd.ctc-posml',
+            'xpng' => 'image/png',
+            'xpnm' => 'image/x-portable-anymap',
+            'xportpkg' => 'application/vnd.macports.portpkg',
+            'xpot' => 'application/vnd.ms-powerpoint',
+            'xppd' => 'application/vnd.cups-ppd',
+            'xppm' => 'image/x-portable-pixmap',
+            'xpps' => 'application/vnd.ms-powerpoint',
+
+            'xppt' => 'application/vnd.ms-powerpoint',
+            'xpqa' => 'application/vnd.palm',
+            'xprc' => 'application/vnd.palm',
+            'xpre' => 'application/vnd.lotus-freelance',
+            'xprf' => 'application/pics-rules',
+            'xps' => 'application/postscript',
+            'xpsb' => 'application/vnd.3gpp.pic-bw-small',
+            'xpsd' => 'image/vnd.adobe.photoshop',
+            'xptid' => 'application/vnd.pvi.ptid1',
+
+            'xpub' => 'application/x-mspublisher',
+            'xpvb' => 'application/vnd.3gpp.pic-bw-var',
+            'xpwn' => 'application/vnd.3m.post-it-notes',
+            'xqam' => 'application/vnd.epson.quickanime',
+            'xqbo' => 'application/vnd.intu.qbo',
+            'xqfx' => 'application/vnd.intu.qfx',
+            'xqps' => 'application/vnd.publishare-delta-tree',
+            'xqt' => 'video/quicktime',
+            'xra' => 'audio/x-pn-realaudio',
+
+            'xram' => 'audio/x-pn-realaudio',
+            'xrar' => 'application/x-rar-compressed',
+            'xras' => 'image/x-cmu-raster',
+            'xrcprofile' => 'application/vnd.ipunplugged.rcprofile',
+            'xrdf' => 'application/rdf+xml',
+            'xrdz' => 'application/vnd.data-vision.rdz',
+            'xrep' => 'application/vnd.businessobjects',
+            'xrgb' => 'image/x-rgb',
+            'xrif' => 'application/reginfo+xml',
+
+            'xrl' => 'application/resource-lists+xml',
+            'xrlc' => 'image/vnd.fujixerox.edmics-rlc',
+            'xrm' => 'application/vnd.rn-realmedia',
+            'xrmi' => 'audio/midi',
+            'xrmp' => 'audio/x-pn-realaudio-plugin',
+            'xrms' => 'application/vnd.jcp.javame.midlet-rms',
+            'xrnc' => 'application/relax-ng-compact-syntax',
+            'xrpss' => 'application/vnd.nokia.radio-presets',
+            'xrpst' => 'application/vnd.nokia.radio-preset',
+
+            'xrq' => 'application/sparql-query',
+            'xrs' => 'application/rls-services+xml',
+            'xrsd' => 'application/rsd+xml',
+            'xrss' => 'application/rss+xml',
+            'xrtf' => 'application/rtf',
+            'xrtx' => 'text/richtext',
+            'xsaf' => 'application/vnd.yamaha.smaf-audio',
+            'xsbml' => 'application/sbml+xml',
+            'xsc' => 'application/vnd.ibm.secure-container',
+
+            'xscd' => 'application/x-msschedule',
+            'xscm' => 'application/vnd.lotus-screencam',
+            'xscq' => 'application/scvp-cv-request',
+            'xscs' => 'application/scvp-cv-response',
+            'xsdp' => 'application/sdp',
+            'xsee' => 'application/vnd.seemail',
+            'xsema' => 'application/vnd.sema',
+            'xsemd' => 'application/vnd.semd',
+            'xsemf' => 'application/vnd.semf',
+
+            'xsetpay' => 'application/set-payment-initiation',
+            'xsetreg' => 'application/set-registration-initiation',
+            'xsfs' => 'application/vnd.spotfire.sfs',
+            'xsgm' => 'text/sgml',
+            'xsgml' => 'text/sgml',
+            'xsh' => 'application/x-sh',
+            'xshar' => 'application/x-shar',
+            'xshf' => 'application/shf+xml',
+            'xsilo' => 'model/mesh',
+
+            'xsit' => 'application/x-stuffit',
+            'xsitx' => 'application/x-stuffitx',
+            'xslt' => 'application/vnd.epson.salt',
+            'xsnd' => 'audio/basic',
+            'xspf' => 'application/vnd.yamaha.smaf-phrase',
+            'xspl' => 'application/x-futuresplash',
+            'xspot' => 'text/vnd.in3d.spot',
+            'xspp' => 'application/scvp-vp-response',
+            'xspq' => 'application/scvp-vp-request',
+
+            'xsrc' => 'application/x-wais-source',
+            'xsrx' => 'application/sparql-results+xml',
+            'xssf' => 'application/vnd.epson.ssf',
+            'xssml' => 'application/ssml+xml',
+            'xstf' => 'application/vnd.wt.stf',
+            'xstk' => 'application/hyperstudio',
+            'xstr' => 'application/vnd.pg.format',
+            'xsus' => 'application/vnd.sus-calendar',
+            'xsusp' => 'application/vnd.sus-calendar',
+
+            'xsv4cpio' => 'application/x-sv4cpio',
+            'xsv4crc' => 'application/x-sv4crc',
+            'xsvd' => 'application/vnd.svd',
+            'xswf' => 'application/x-shockwave-flash',
+            'xtao' => 'application/vnd.tao.intent-module-archive',
+            'xtar' => 'application/x-tar',
+            'xtcap' => 'application/vnd.3gpp2.tcap',
+            'xtcl' => 'application/x-tcl',
+            'xtex' => 'application/x-tex',
+
+            'xtext' => 'text/plain',
+            'xtif' => 'image/tiff',
+            'xtiff' => 'image/tiff',
+            'xtmo' => 'application/vnd.tmobile-livetv',
+            'xtorrent' => 'application/x-bittorrent',
+            'xtpl' => 'application/vnd.groove-tool-template',
+            'xtpt' => 'application/vnd.trid.tpt',
+            'xtra' => 'application/vnd.trueapp',
+            'xtrm' => 'application/x-msterminal',
+
+            'xtsv' => 'text/tab-separated-values',
+            'xtxd' => 'application/vnd.genomatix.tuxedo',
+            'xtxf' => 'application/vnd.mobius.txf',
+            'xtxt' => 'text/plain',
+            'xumj' => 'application/vnd.umajin',
+            'xunityweb' => 'application/vnd.unity',
+            'xuoml' => 'application/vnd.uoml+xml',
+            'xuri' => 'text/uri-list',
+            'xuris' => 'text/uri-list',
+
+            'xurls' => 'text/uri-list',
+            'xustar' => 'application/x-ustar',
+            'xutz' => 'application/vnd.uiq.theme',
+            'xuu' => 'text/x-uuencode',
+            'xvcd' => 'application/x-cdlink',
+            'xvcf' => 'text/x-vcard',
+            'xvcg' => 'application/vnd.groove-vcard',
+            'xvcs' => 'text/x-vcalendar',
+            'xvcx' => 'application/vnd.vcx',
+
+            'xvis' => 'application/vnd.visionary',
+            'xviv' => 'video/vnd.vivo',
+            'xvrml' => 'model/vrml',
+            'xvsd' => 'application/vnd.visio',
+            'xvsf' => 'application/vnd.vsf',
+            'xvss' => 'application/vnd.visio',
+            'xvst' => 'application/vnd.visio',
+            'xvsw' => 'application/vnd.visio',
+            'xvtu' => 'model/vnd.vtu',
+
+            'xvxml' => 'application/voicexml+xml',
+            'xwav' => 'audio/x-wav',
+            'xwax' => 'audio/x-ms-wax',
+            'xwbmp' => 'image/vnd.wap.wbmp',
+            'xwbs' => 'application/vnd.criticaltools.wbs+xml',
+            'xwbxml' => 'application/vnd.wap.wbxml',
+            'xwcm' => 'application/vnd.ms-works',
+            'xwdb' => 'application/vnd.ms-works',
+            'xwks' => 'application/vnd.ms-works',
+
+            'xwm' => 'video/x-ms-wm',
+            'xwma' => 'audio/x-ms-wma',
+            'xwmd' => 'application/x-ms-wmd',
+            'xwmf' => 'application/x-msmetafile',
+            'xwml' => 'text/vnd.wap.wml',
+            'xwmlc' => 'application/vnd.wap.wmlc',
+            'xwmls' => 'text/vnd.wap.wmlscript',
+            'xwmlsc' => 'application/vnd.wap.wmlscriptc',
+            'xwmv' => 'video/x-ms-wmv',
+
+            'xwmx' => 'video/x-ms-wmx',
+            'xwmz' => 'application/x-ms-wmz',
+            'xwpd' => 'application/vnd.wordperfect',
+            'xwpl' => 'application/vnd.ms-wpl',
+            'xwps' => 'application/vnd.ms-works',
+            'xwqd' => 'application/vnd.wqd',
+            'xwri' => 'application/x-mswrite',
+            'xwrl' => 'model/vrml',
+            'xwsdl' => 'application/wsdl+xml',
+
+            'xwspolicy' => 'application/wspolicy+xml',
+            'xwtb' => 'application/vnd.webturbo',
+            'xwvx' => 'video/x-ms-wvx',
+            'xx3d' => 'application/vnd.hzn-3d-crossword',
+            'xxar' => 'application/vnd.xara',
+            'xxbd' => 'application/vnd.fujixerox.docuworks.binder',
+            'xxbm' => 'image/x-xbitmap',
+            'xxdm' => 'application/vnd.syncml.dm+xml',
+            'xxdp' => 'application/vnd.adobe.xdp+xml',
+
+            'xxdw' => 'application/vnd.fujixerox.docuworks',
+            'xxenc' => 'application/xenc+xml',
+            'xxfdf' => 'application/vnd.adobe.xfdf',
+            'xxfdl' => 'application/vnd.xfdl',
+            'xxht' => 'application/xhtml+xml',
+            'xxhtml' => 'application/xhtml+xml',
+            'xxhvml' => 'application/xv+xml',
+            'xxif' => 'image/vnd.xiff',
+            'xxla' => 'application/vnd.ms-excel',
+
+            'xxlc' => 'application/vnd.ms-excel',
+            'xxlm' => 'application/vnd.ms-excel',
+            'xxls' => 'application/vnd.ms-excel',
+            'xxlt' => 'application/vnd.ms-excel',
+            'xxlw' => 'application/vnd.ms-excel',
+            'xxml' => 'application/xml',
+            'xxo' => 'application/vnd.olpc-sugar',
+            'xxop' => 'application/xop+xml',
+            'xxpm' => 'image/x-xpixmap',
+
+            'xxpr' => 'application/vnd.is-xpr',
+            'xxps' => 'application/vnd.ms-xpsdocument',
+            'xxsl' => 'application/xml',
+            'xxslt' => 'application/xslt+xml',
+            'xxsm' => 'application/vnd.syncml+xml',
+            'xxspf' => 'application/xspf+xml',
+            'xxul' => 'application/vnd.mozilla.xul+xml',
+            'xxvm' => 'application/xv+xml',
+            'xxvml' => 'application/xv+xml',
+
+            'xxwd' => 'image/x-xwindowdump',
+            'xxyz' => 'chemical/x-xyz',
+            'xzaz' => 'application/vnd.zzazz.deck+xml',
+            'xzip' => 'application/zip',
+            'xzmm' => 'application/vnd.handheld-entertainment+xml',
+        );
+
+    /**
+     * Extend list of MIME types if needed from config
+     */
+    public function __construct()
+    {
+        $nodes = Mage::getConfig()->getNode('global/mime/types');
+        if ($nodes) {
+            $nodes = (array)$nodes;
+            foreach ($nodes as $key => $value) {
+                $this->_mimeTypes[$key] = $value;
+            }
+        }
+    }
+
+    /**
+     * Get MIME type by file extension from list of pre-defined MIME types
+     *
+     * @param $ext
+     * @return string
+     */
+    public function getMimeTypeByExtension($ext)
+    {
+        $type = 'x' . $ext;
+        if (isset($this->_mimeTypes[$type])) {
+            return $this->_mimeTypes[$type];
+        }
+        return 'application/octet-stream';
+    }
+
+    /**
+     * Get all MIME Types
+     *
+     * @return array
+     */
+    public function getMimeTypes()
+    {
+        return $this->_mimeTypes;
+    }
+
+    /**
+     * Get array of MIME types associated with given file extension
+     *
+     * @param array|string $extensionsList
+     * @return array
+     */
+    public function getMimeTypeFromExtensionList($extensionsList)
+    {
+        if (is_string($extensionsList)) {
+            $extensionsList = array_map('trim', explode(',', $extensionsList));
+        }
+
+        return array_map(array($this, 'getMimeTypeByExtension'), $extensionsList);
+    }
+
+    /**
+     * Get post_max_size server setting
+     *
+     * @return string
+     */
+    public function getPostMaxSize()
+    {
+        return ini_get('post_max_size');
+    }
+
+    /**
+     * Get upload_max_filesize server setting
+     *
+     * @return string
+     */
+    public function getUploadMaxSize()
+    {
+        return ini_get('upload_max_filesize');
+    }
+
+    /**
+     * Get max upload size
+     *
+     * @return mixed
+     */
+    public function getDataMaxSize()
+    {
+        return min($this->getPostMaxSize(), $this->getUploadMaxSize());
+    }
+
+    /**
+     * Get maximum upload size in bytes
+     *
+     * @return int
+     */
+    public function getDataMaxSizeInBytes()
+    {
+        $iniSize = $this->getDataMaxSize();
+        $size = substr($iniSize, 0, strlen($iniSize)-1);
+        $parsedSize = 0;
+        switch (strtolower(substr($iniSize, strlen($iniSize)-1))) {
+            case 't':
+                $parsedSize = $size*(1024*1024*1024*1024);
+                break;
+            case 'g':
+                $parsedSize = $size*(1024*1024*1024);
+                break;
+            case 'm':
+                $parsedSize = $size*(1024*1024);
+                break;
+            case 'k':
+                $parsedSize = $size*1024;
+                break;
+            case 'b':
+            default:
+                $parsedSize = $size;
+                break;
+        }
+        return (int)$parsedSize;
+    }
+
+}
diff --git app/code/core/Mage/Uploader/Model/Config/Abstract.php app/code/core/Mage/Uploader/Model/Config/Abstract.php
new file mode 100644
index 0000000..da2ea63
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Abstract.php
@@ -0,0 +1,69 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+abstract class Mage_Uploader_Model_Config_Abstract extends Varien_Object
+{
+    /**
+     * Get file helper
+     *
+     * @return Mage_Uploader_Helper_File
+     */
+    protected function _getHelper()
+    {
+        return Mage::helper('uploader/file');
+    }
+
+    /**
+     * Set/Get attribute wrapper
+     * Also set data in cameCase for config values
+     *
+     * @param string $method
+     * @param array $args
+     * @return bool|mixed|Varien_Object
+     * @throws Varien_Exception
+     */
+    public function __call($method, $args)
+    {
+        $key = lcfirst($this->_camelize(substr($method,3)));
+        switch (substr($method, 0, 3)) {
+            case 'get' :
+                $data = $this->getData($key, isset($args[0]) ? $args[0] : null);
+                return $data;
+
+            case 'set' :
+                $result = $this->setData($key, isset($args[0]) ? $args[0] : null);
+                return $result;
+
+            case 'uns' :
+                $result = $this->unsetData($key);
+                return $result;
+
+            case 'has' :
+                return isset($this->_data[$key]);
+        }
+        throw new Varien_Exception("Invalid method ".get_class($this)."::".$method."(".print_r($args,1).")");
+    }
+}
diff --git app/code/core/Mage/Uploader/Model/Config/Browsebutton.php app/code/core/Mage/Uploader/Model/Config/Browsebutton.php
new file mode 100644
index 0000000..eaa5d64
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Browsebutton.php
@@ -0,0 +1,63 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+
+ * @method Mage_Uploader_Model_Config_Browsebutton setDomNodes(array $domNodesIds)
+ *      Array of element browse buttons ids
+ * @method Mage_Uploader_Model_Config_Browsebutton setIsDirectory(bool $isDirectory)
+ *      Pass in true to allow directories to be selected (Google Chrome only)
+ * @method Mage_Uploader_Model_Config_Browsebutton setSingleFile(bool $isSingleFile)
+ *      To prevent multiple file uploads set this to true.
+ *      Also look at config parameter singleFile (Mage_Uploader_Model_Config_Uploader setSingleFile())
+ * @method Mage_Uploader_Model_Config_Browsebutton setAttributes(array $attributes)
+ *      Pass object of keys and values to set custom attributes on input fields.
+ *      @see http://www.w3.org/TR/html-markup/input.file.html#input.file-attributes
+ */
+
+class Mage_Uploader_Model_Config_Browsebutton extends Mage_Uploader_Model_Config_Abstract
+{
+    /**
+     * Set params for browse button
+     */
+    protected function _construct()
+    {
+        $this->setIsDirectory(false);
+    }
+
+    /**
+     * Get MIME types from files extensions
+     *
+     * @param string|array $exts
+     * @return string
+     */
+    public function getMimeTypesByExtensions($exts)
+    {
+        $mimes = array_unique($this->_getHelper()->getMimeTypeFromExtensionList($exts));
+
+        // Not include general file type
+        unset($mimes['application/octet-stream']);
+
+        return implode(',', $mimes);
+    }
+}
diff --git app/code/core/Mage/Uploader/Model/Config/Misc.php app/code/core/Mage/Uploader/Model/Config/Misc.php
new file mode 100644
index 0000000..3c70ad3
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Misc.php
@@ -0,0 +1,46 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ * 
+ * @method Mage_Uploader_Model_Config_Misc setMaxSizePlural (string $sizePlural) Set plural info about max upload size
+ * @method Mage_Uploader_Model_Config_Misc setMaxSizeInBytes (int $sizeInBytes) Set max upload size in bytes
+ * @method Mage_Uploader_Model_Config_Misc setReplaceBrowseWithRemove (bool $replaceBrowseWithRemove)
+ *      Replace browse button with remove
+ *
+ * Class Mage_Uploader_Model_Config_Misc
+ */
+
+class Mage_Uploader_Model_Config_Misc extends Mage_Uploader_Model_Config_Abstract
+{
+    /**
+     * Prepare misc params
+     */
+    protected function _construct()
+    {
+        $this
+            ->setMaxSizeInBytes($this->_getHelper()->getDataMaxSizeInBytes())
+            ->setMaxSizePlural($this->_getHelper()->getDataMaxSize())
+        ;
+    }
+}
diff --git app/code/core/Mage/Uploader/Model/Config/Uploader.php app/code/core/Mage/Uploader/Model/Config/Uploader.php
new file mode 100644
index 0000000..0fc6f0c
--- /dev/null
+++ app/code/core/Mage/Uploader/Model/Config/Uploader.php
@@ -0,0 +1,122 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/**
+ * @method Mage_Uploader_Model_Config_Uploader setTarget(string $url)
+ *      The target URL for the multipart POST request.
+ * @method Mage_Uploader_Model_Config_Uploader setSingleFile(bool $isSingleFile)
+ *      Enable single file upload.
+ *      Once one file is uploaded, second file will overtake existing one, first one will be canceled.
+ * @method Mage_Uploader_Model_Config_Uploader setChunkSize(int $chunkSize) The size in bytes of each uploaded chunk of data.
+ * @method Mage_Uploader_Model_Config_Uploader setForceChunkSize(bool $forceChunkSize)
+ *      Force all chunks to be less or equal than chunkSize.
+ * @method Mage_Uploader_Model_Config_Uploader setSimultaneousUploads(int $amountOfSimultaneousUploads)
+ * @method Mage_Uploader_Model_Config_Uploader setFileParameterName(string $fileUploadParam)
+ * @method Mage_Uploader_Model_Config_Uploader setQuery(array $additionalQuery)
+ * @method Mage_Uploader_Model_Config_Uploader setHeaders(array $headers)
+ *      Extra headers to include in the multipart POST with data.
+ * @method Mage_Uploader_Model_Config_Uploader setWithCredentials(bool $isCORS)
+ *      Standard CORS requests do not send or set any cookies by default.
+ *      In order to include cookies as part of the request, you need to set the withCredentials property to true.
+ * @method Mage_Uploader_Model_Config_Uploader setMethod(string $sendMethod)
+ *       Method to use when POSTing chunks to the server. Defaults to "multipart"
+ * @method Mage_Uploader_Model_Config_Uploader setTestMethod(string $testMethod) Defaults to "GET"
+ * @method Mage_Uploader_Model_Config_Uploader setUploadMethod(string $uploadMethod) Defaults to "POST"
+ * @method Mage_Uploader_Model_Config_Uploader setAllowDuplicateUploads(bool $allowDuplicateUploads)
+ *      Once a file is uploaded, allow reupload of the same file. By default, if a file is already uploaded,
+ *      it will be skipped unless the file is removed from the existing Flow object.
+ * @method Mage_Uploader_Model_Config_Uploader setPrioritizeFirstAndLastChunk(bool $prioritizeFirstAndLastChunk)
+ *      This can be handy if you can determine if a file is valid for your service from only the first or last chunk.
+ * @method Mage_Uploader_Model_Config_Uploader setTestChunks(bool $prioritizeFirstAndLastChunk)
+ *      Make a GET request to the server for each chunks to see if it already exists.
+ * @method Mage_Uploader_Model_Config_Uploader setPreprocess(bool $prioritizeFirstAndLastChunk)
+ *      Optional function to process each chunk before testing & sending.
+ * @method Mage_Uploader_Model_Config_Uploader setInitFileFn(string $function)
+ *      Optional function to initialize the fileObject (js).
+ * @method Mage_Uploader_Model_Config_Uploader setReadFileFn(string $function)
+ *      Optional function wrapping reading operation from the original file.
+ * @method Mage_Uploader_Model_Config_Uploader setGenerateUniqueIdentifier(string $function)
+ *      Override the function that generates unique identifiers for each file. Defaults to "null"
+ * @method Mage_Uploader_Model_Config_Uploader setMaxChunkRetries(int $maxChunkRetries) Defaults to 0
+ * @method Mage_Uploader_Model_Config_Uploader setChunkRetryInterval(int $chunkRetryInterval) Defaults to "undefined"
+ * @method Mage_Uploader_Model_Config_Uploader setProgressCallbacksInterval(int $progressCallbacksInterval)
+ * @method Mage_Uploader_Model_Config_Uploader setSpeedSmoothingFactor(int $speedSmoothingFactor)
+ *      Used for calculating average upload speed. Number from 1 to 0.
+ *      Set to 1 and average upload speed wil be equal to current upload speed.
+ *      For longer file uploads it is better set this number to 0.02,
+ *      because time remaining estimation will be more accurate.
+ * @method Mage_Uploader_Model_Config_Uploader setSuccessStatuses(array $successStatuses)
+ *      Response is success if response status is in this list
+ * @method Mage_Uploader_Model_Config_Uploader setPermanentErrors(array $permanentErrors)
+ *      Response fails if response status is in this list
+ *
+ * Class Mage_Uploader_Model_Config_Uploader
+ */
+
+class Mage_Uploader_Model_Config_Uploader extends Mage_Uploader_Model_Config_Abstract
+{
+    /**
+     * Type of upload
+     */
+    const UPLOAD_TYPE = 'multipart';
+
+    /**
+     * Test chunks on resumable uploads
+     */
+    const TEST_CHUNKS = false;
+
+    /**
+     * Used for calculating average upload speed.
+     */
+    const SMOOTH_UPLOAD_FACTOR = 0.02;
+
+    /**
+     * Progress check interval
+     */
+    const PROGRESS_CALLBACK_INTERVAL = 0;
+
+    /**
+     * Set default values for uploader
+     */
+    protected function _construct()
+    {
+        $this
+            ->setChunkSize($this->_getHelper()->getDataMaxSizeInBytes())
+            ->setWithCredentials(false)
+            ->setForceChunkSize(false)
+            ->setQuery(array(
+                'form_key' => Mage::getSingleton('core/session')->getFormKey()
+            ))
+            ->setMethod(self::UPLOAD_TYPE)
+            ->setAllowDuplicateUploads(true)
+            ->setPrioritizeFirstAndLastChunk(false)
+            ->setTestChunks(self::TEST_CHUNKS)
+            ->setSpeedSmoothingFactor(self::SMOOTH_UPLOAD_FACTOR)
+            ->setProgressCallbacksInterval(self::PROGRESS_CALLBACK_INTERVAL)
+            ->setSuccessStatuses(array(200, 201, 202))
+            ->setPermanentErrors(array(404, 415, 500, 501));
+    }
+}
diff --git app/code/core/Mage/Uploader/etc/config.xml app/code/core/Mage/Uploader/etc/config.xml
new file mode 100644
index 0000000..78584d5
--- /dev/null
+++ app/code/core/Mage/Uploader/etc/config.xml
@@ -0,0 +1,51 @@
+<?xml version="1.0"?>
+<!--
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+-->
+<config>
+    <modules>
+        <Mage_Uploader>
+            <version>0.1.0</version>
+        </Mage_Uploader>
+    </modules>
+    <global>
+        <blocks>
+            <uploader>
+                <class>Mage_Uploader_Block</class>
+            </uploader>
+        </blocks>
+        <helpers>
+            <uploader>
+                <class>Mage_Uploader_Helper</class>
+            </uploader>
+        </helpers>
+        <models>
+            <uploader>
+                <class>Mage_Uploader_Model</class>
+            </uploader>
+        </models>
+    </global>
+</config>
diff --git app/code/core/Mage/Uploader/etc/jstranslator.xml app/code/core/Mage/Uploader/etc/jstranslator.xml
new file mode 100644
index 0000000..8b1fe0a
--- /dev/null
+++ app/code/core/Mage/Uploader/etc/jstranslator.xml
@@ -0,0 +1,44 @@
+<?xml version="1.0"?>
+<!--
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Mage
+ * @package     Mage_Uploader
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+-->
+<jstranslator>
+    <uploader-exceed_max-1 translate="message" module="uploader">
+        <message>Maximum allowed file size for upload is</message>
+    </uploader-exceed_max-1>
+    <uploader-exceed_max-2 translate="message" module="uploader">
+        <message>Please check your server PHP settings.</message>
+    </uploader-exceed_max-2>
+    <uploader-tab-change-event-confirm translate="message" module="uploader">
+        <message>There are files that were selected but not uploaded yet. After switching to another tab your selections will be lost. Do you wish to continue ?</message>
+    </uploader-tab-change-event-confirm>
+    <uploader-complete-event-text translate="message" module="uploader">
+        <message>Complete</message>
+    </uploader-complete-event-text>
+    <uploader-uploading-progress translate="message" module="uploader">
+        <message>Uploading...</message>
+    </uploader-uploading-progress>
+</jstranslator>
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php
index 9b8adc0..1be8973 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl.php
@@ -538,8 +538,8 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl
                 $ch = curl_init();
                 curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
                 curl_setopt($ch, CURLOPT_URL, $url);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
+                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
+                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
                 curl_setopt($ch, CURLOPT_POSTFIELDS, $request);
                 $responseBody = curl_exec($ch);
                 curl_close($ch);
@@ -1037,8 +1037,8 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl
             $ch = curl_init();
             curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
             curl_setopt($ch, CURLOPT_URL, $url);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
+            curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
             curl_setopt($ch, CURLOPT_POSTFIELDS, $request);
             $responseBody = curl_exec($ch);
             $debugData['result'] = $responseBody;
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php
index 98a3b03..f17ba76 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Dhl/International.php
@@ -837,7 +837,12 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl_International
     {
         $client = new Varien_Http_Client();
         $client->setUri((string)$this->getConfigData('gateway_url'));
-        $client->setConfig(array('maxredirects' => 0, 'timeout' => 30));
+        $client->setConfig(array(
+            'maxredirects' => 0,
+            'timeout' => 30,
+            'verifypeer' => $this->getConfigFlag('verify_peer'),
+            'verifyhost' => 2,
+        ));
         $client->setRawData(utf8_encode($request));
         return $client->request(Varien_Http_Client::POST)->getBody();
     }
@@ -1411,7 +1416,12 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl_International
             try {
                 $client = new Varien_Http_Client();
                 $client->setUri((string)$this->getConfigData('gateway_url'));
-                $client->setConfig(array('maxredirects' => 0, 'timeout' => 30));
+                $client->setConfig(array(
+                    'maxredirects' => 0,
+                    'timeout' => 30,
+                    'verifypeer' => $this->getConfigFlag('verify_peer'),
+                    'verifyhost' => 2,
+                ));
                 $client->setRawData($request);
                 $responseBody = $client->request(Varien_Http_Client::POST)->getBody();
                 $debugData['result'] = $responseBody;
@@ -1603,7 +1613,12 @@ class Mage_Usa_Model_Shipping_Carrier_Dhl_International
             try {
                 $client = new Varien_Http_Client();
                 $client->setUri((string)$this->getConfigData('gateway_url'));
-                $client->setConfig(array('maxredirects' => 0, 'timeout' => 30));
+                $client->setConfig(array(
+                    'maxredirects' => 0,
+                    'timeout' => 30,
+                    'verifypeer' => $this->getConfigFlag('verify_peer'),
+                    'verifyhost' => 2,
+                ));
                 $client->setRawData($request);
                 $responseBody = $client->request(Varien_Http_Client::POST)->getBody();
                 $debugData['result'] = $responseBody;
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php
index 57d3df4..8aa091e 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Fedex.php
@@ -604,6 +604,7 @@ class Mage_Usa_Model_Shipping_Carrier_Fedex
     /**
      * Get xml quotes
      *
+     * @deprecated
      * @return Mage_Shipping_Model_Rate_Result
      */
     protected function _getXmlQuotes()
@@ -663,8 +664,8 @@ class Mage_Usa_Model_Shipping_Carrier_Fedex
                 $ch = curl_init();
                 curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
                 curl_setopt($ch, CURLOPT_URL, $url);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 0);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 0);
+                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, 1);
+                curl_setopt($ch, CURLOPT_SSL_VERIFYHOST, 2);
                 curl_setopt($ch, CURLOPT_POSTFIELDS, $request);
                 $responseBody = curl_exec($ch);
                 curl_close ($ch);
diff --git app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php
index 3cfeaba..e365b70 100644
--- app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php
+++ app/code/core/Mage/Usa/Model/Shipping/Carrier/Ups.php
@@ -937,7 +937,7 @@ XMLRequest;
                 curl_setopt($ch, CURLOPT_POST, 1);
                 curl_setopt($ch, CURLOPT_POSTFIELDS, $xmlRequest);
                 curl_setopt($ch, CURLOPT_TIMEOUT, 30);
-                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, (boolean)$this->getConfigFlag('mode_xml'));
+                curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
                 $xmlResponse = curl_exec ($ch);
 
                 $debugData['result'] = $xmlResponse;
@@ -1578,7 +1578,7 @@ XMLAuth;
             curl_setopt($ch, CURLOPT_POST, 1);
             curl_setopt($ch, CURLOPT_POSTFIELDS, $this->_xmlAccessRequest . $xmlRequest->asXML());
             curl_setopt($ch, CURLOPT_TIMEOUT, 30);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, (boolean)$this->getConfigFlag('mode_xml'));
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
             $xmlResponse = curl_exec ($ch);
 
             $debugData['result'] = $xmlResponse;
@@ -1636,7 +1636,7 @@ XMLAuth;
             curl_setopt($ch, CURLOPT_POST, 1);
             curl_setopt($ch, CURLOPT_POSTFIELDS, $xmlRequest);
             curl_setopt($ch, CURLOPT_TIMEOUT, 30);
-            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, (boolean)$this->getConfigFlag('mode_xml'));
+            curl_setopt($ch, CURLOPT_SSL_VERIFYPEER, $this->getConfigFlag('verify_peer'));
             $xmlResponse = curl_exec($ch);
             if ($xmlResponse === false) {
                 throw new Exception(curl_error($ch));
diff --git app/code/core/Mage/Usa/etc/config.xml app/code/core/Mage/Usa/etc/config.xml
index 831455f..ff028a1 100644
--- app/code/core/Mage/Usa/etc/config.xml
+++ app/code/core/Mage/Usa/etc/config.xml
@@ -114,6 +114,7 @@
                 <dutypaymenttype>R</dutypaymenttype>
                 <free_method>G</free_method>
                 <gateway_url>https://eCommerce.airborne.com/ApiLandingTest.asp</gateway_url>
+                <verify_peer>0</verify_peer>
                 <id backend_model="adminhtml/system_config_backend_encrypted"/>
                 <model>usa/shipping_carrier_dhl</model>
                 <password backend_model="adminhtml/system_config_backend_encrypted"/>
@@ -169,6 +170,7 @@
                 <tracking_xml_url>https://onlinetools.ups.com/ups.app/xml/Track</tracking_xml_url>
                 <shipconfirm_xml_url>https://onlinetools.ups.com/ups.app/xml/ShipConfirm</shipconfirm_xml_url>
                 <shipaccept_xml_url>https://onlinetools.ups.com/ups.app/xml/ShipAccept</shipaccept_xml_url>
+                <verify_peer>0</verify_peer>
                 <handling>0</handling>
                 <model>usa/shipping_carrier_ups</model>
                 <pickup>CC</pickup>
@@ -219,6 +221,7 @@
                 <doc_methods>2,5,6,7,9,B,C,D,U,K,L,G,W,I,N,O,R,S,T,X</doc_methods>
                 <free_method>G</free_method>
                 <gateway_url>https://xmlpi-ea.dhl.com/XMLShippingServlet</gateway_url>
+                <verify_peer>0</verify_peer>
                 <id backend_model="adminhtml/system_config_backend_encrypted"/>
                 <password backend_model="adminhtml/system_config_backend_encrypted"/>
                 <shipment_type>N</shipment_type>
diff --git app/code/core/Mage/Usa/etc/system.xml app/code/core/Mage/Usa/etc/system.xml
index 9f446b0..1a31b22 100644
--- app/code/core/Mage/Usa/etc/system.xml
+++ app/code/core/Mage/Usa/etc/system.xml
@@ -130,6 +130,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
                         </gateway_url>
+                        <verify_peer translate="label">
+                            <label>Enable SSL Verification</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>30</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </verify_peer>
                         <handling_type translate="label">
                             <label>Calculate Handling Fee</label>
                             <frontend_type>select</frontend_type>
@@ -744,6 +753,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
                         </gateway_url>
+                        <verify_peer translate="label">
+                            <label>Enable SSL Verification</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>45</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </verify_peer>
                         <gateway_xml_url translate="label">
                             <label>Gateway XML URL</label>
                             <frontend_type>text</frontend_type>
@@ -1264,6 +1282,15 @@
                             <show_in_website>1</show_in_website>
                             <show_in_store>0</show_in_store>
                         </gateway_url>
+                        <verify_peer translate="label">
+                            <label>Enable SSL Verification</label>
+                            <frontend_type>select</frontend_type>
+                            <source_model>adminhtml/system_config_source_yesno</source_model>
+                            <sort_order>30</sort_order>
+                            <show_in_default>1</show_in_default>
+                            <show_in_website>1</show_in_website>
+                            <show_in_store>0</show_in_store>
+                        </verify_peer>
                         <title translate="label">
                             <label>Title</label>
                             <frontend_type>text</frontend_type>
diff --git app/code/core/Mage/Wishlist/Helper/Data.php app/code/core/Mage/Wishlist/Helper/Data.php
index 663fbbe..bdea0df 100644
--- app/code/core/Mage/Wishlist/Helper/Data.php
+++ app/code/core/Mage/Wishlist/Helper/Data.php
@@ -274,7 +274,10 @@ class Mage_Wishlist_Helper_Data extends Mage_Core_Helper_Abstract
     public function getRemoveUrl($item)
     {
         return $this->_getUrl('wishlist/index/remove',
-            array('item' => $item->getWishlistItemId())
+            array(
+                'item' => $item->getWishlistItemId(),
+                Mage_Core_Model_Url::FORM_KEY => $this->_getSingletonModel('core/session')->getFormKey()
+            )
         );
     }
 
diff --git app/code/core/Mage/Wishlist/controllers/IndexController.php app/code/core/Mage/Wishlist/controllers/IndexController.php
index e1c05df..c18fa0e 100644
--- app/code/core/Mage/Wishlist/controllers/IndexController.php
+++ app/code/core/Mage/Wishlist/controllers/IndexController.php
@@ -434,6 +434,9 @@ class Mage_Wishlist_IndexController extends Mage_Wishlist_Controller_Abstract
      */
     public function removeAction()
     {
+        if (!$this->_validateFormKey()) {
+            return $this->_redirect('*/*');
+        }
         $id = (int) $this->getRequest()->getParam('item');
         $item = Mage::getModel('wishlist/item')->load($id);
         if (!$item->getId()) {
diff --git app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php
index 5b37a7a..9db7cf1 100644
--- app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php
+++ app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design.php
@@ -95,4 +95,21 @@ class Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design
     {
         return true;
     }
+
+    /**
+     * Create browse button template
+     *
+     * @return string
+     */
+    public function getBrowseButtonHtml()
+    {
+        return $this->getLayout()->createBlock('adminhtml/widget_button')
+            ->addData(array(
+                'before_html'   => '<div style="display:inline-block; " id="{{file_field}}_{{id}}_file-browse">',
+                'after_html'    => '</div>',
+                'id'            => '{{file_field}}_{{id}}_file-browse_button',
+                'label'         => Mage::helper('uploader')->__('...'),
+                'type'          => 'button',
+            ))->toHtml();
+    }
 }
diff --git app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design/Images.php app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design/Images.php
index da5a799..04288a5 100644
--- app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design/Images.php
+++ app/code/core/Mage/XmlConnect/Block/Adminhtml/Mobile/Edit/Tab/Design/Images.php
@@ -31,7 +31,7 @@
  * @package     Mage_Xmlconnect
  * @author      Magento Core Team <core@magentocommerce.com>
  */
-class Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design_Images extends Mage_Adminhtml_Block_Template
+class Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design_Images extends Mage_Uploader_Block_Single
 {
     /**
      * Init block, set preview template
@@ -116,42 +116,56 @@ class Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design_Images extends Mage
             'application_id' => $this->getApplicationId());
 
         if (isset($image['image_id'])) {
-            $this->getConfig()->setFileSave(Mage::getModel('xmlconnect/images')->getImageUrl($image['image_file']))
-                ->setImageId($image['image_id']);
-
-            $this->getConfig()->setThumbnail(Mage::getModel('xmlconnect/images')->getCustomSizeImageUrl(
+            $this->getMiscConfig()->setData('file_save',
+                Mage::getModel('xmlconnect/images')->getImageUrl($image['image_file']))
+                    ->setImageId($image['image_id']
+            )->setData('thumbnail',
+                Mage::getModel('xmlconnect/images')->getCustomSizeImageUrl(
                 $image['image_file'],
                 Mage_XmlConnect_Helper_Data::THUMBNAIL_IMAGE_WIDTH,
                 Mage_XmlConnect_Helper_Data::THUMBNAIL_IMAGE_HEIGHT
-            ))->setImageId($image['image_id']);
+            ))->setData('image_id', $image['image_id']);
 
             $imageActionData = Mage::helper('xmlconnect')->getApplication()->getImageActionModel()
                 ->getImageActionData($image['image_id']);
             if ($imageActionData) {
-                $this->getConfig()->setImageActionData($imageActionData);
+                $this->getMiscConfig()->setData('image_action_data', $imageActionData);
             }
         }
 
-        if (isset($image['show_uploader'])) {
-            $this->getConfig()->setShowUploader($image['show_uploader']);
-        }
+        $this->getUploaderConfig()
+            ->setFileParameterName($image['image_type'])
+            ->setTarget(
+                Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/uploadimages', $params)
+            );
+
+        $this->getButtonConfig()
+            ->setAttributes(
+                array('accept' => $this->getButtonConfig()->getMimeTypesByExtensions('gif, jpg, jpeg, png'))
+            );
+        $this->getMiscConfig()
+            ->setReplaceBrowseWithRemove(true)
+            ->setData('image_count', $this->getImageCount())
+        ;
+
+        return parent::getJsonConfig();
+    }
 
-        $this->getConfig()->setUrl(
-            Mage::getModel('adminhtml/url')->addSessionParam()->getUrl('*/*/uploadimages', $params)
-        );
-        $this->getConfig()->setParams(array('form_key' => $this->getFormKey()));
-        $this->getConfig()->setFileField($image['image_type']);
-        $this->getConfig()->setFilters(array(
-            'images' => array(
-                'label' => Mage::helper('adminhtml')->__('Images (.gif, .jpg, .png)'),
-                'files' => array('*.gif', '*.jpg','*.jpeg', '*.png')
-        )));
-        $this->getConfig()->setReplaceBrowseWithRemove(true);
-        $this->getConfig()->setWidth('32');
-        $this->getConfig()->setHideUploadButton(true);
-        $this->getConfig()->setImageCount($this->getImageCount());
-
-        return $this->getConfig()->getData();
+    /**
+     * Prepare layout, change button and set front-end element ids mapping
+     *
+     * @return $this
+     */
+    protected function _prepareLayout()
+    {
+        parent::_prepareLayout();
+
+        $this->_addElementIdsMapping(array(
+            'container'     => $this->getHtmlId() . '-new',
+            'idToReplace'   => $this->getHtmlId(),
+        ));
+
+        return $this;
     }
 
     /**
@@ -168,15 +182,12 @@ class Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design_Images extends Mage
     /**
      * Retrieve image config object
      *
-     * @return Varien_Object
+     * @deprecated
+     * @return $this
      */
     public function getConfig()
     {
-        if(is_null($this->_config)) {
-            $this->_config = new Varien_Object();
-        }
-
-        return $this->_config;
+        return $this;
     }
 
     /**
@@ -186,7 +197,13 @@ class Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design_Images extends Mage
      */
     public function clearConfig()
     {
-        $this->_config = null;
+        $this->getMiscConfig()
+            ->unsetData('image_id')
+            ->unsetData('file_save')
+            ->unsetData('thumbnail')
+            ->unsetData('image_count')
+        ;
+        $this->getUploaderConfig()->unsetFileParameterName();
         return $this;
     }
 }
diff --git app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
index 59f4b88..0c6f584 100644
--- app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
+++ app/code/core/Mage/XmlConnect/controllers/Adminhtml/MobileController.php
@@ -337,7 +337,7 @@ class Mage_XmlConnect_Adminhtml_MobileController extends Mage_Adminhtml_Controll
             curl_setopt($curlHandler, CURLOPT_POSTFIELDS, $params);
             curl_setopt($curlHandler, CURLOPT_SSL_VERIFYHOST, 2);
             curl_setopt($curlHandler, CURLOPT_RETURNTRANSFER, 1);
-            curl_setopt($curlHandler, CURLOPT_SSL_VERIFYPEER, 0);
+            curl_setopt($curlHandler, CURLOPT_SSL_VERIFYPEER, 1);
             curl_setopt($curlHandler, CURLOPT_TIMEOUT, 60);
 
             // Execute the request.
@@ -1377,9 +1377,9 @@ class Mage_XmlConnect_Adminhtml_MobileController extends Mage_Adminhtml_Controll
     public function uploadImagesAction()
     {
         $data = $this->getRequest()->getParams();
-        if (isset($data['Filename'])) {
+        if (isset($data['flowFilename'])) {
             // Add random string to uploaded file new
-            $newFileName = Mage::helper('core')->getRandomString(5) . '_' . $data['Filename'];
+            $newFileName = Mage::helper('core')->getRandomString(5) . '_' . $data['flowFilename'];
         }
         try {
             $this->_initApp();
diff --git app/design/adminhtml/default/default/layout/cms.xml app/design/adminhtml/default/default/layout/cms.xml
index 23be193..e8650b6 100644
--- app/design/adminhtml/default/default/layout/cms.xml
+++ app/design/adminhtml/default/default/layout/cms.xml
@@ -82,7 +82,9 @@
         </reference>
         <reference name="content">
             <block name="wysiwyg_images.content"  type="adminhtml/cms_wysiwyg_images_content" template="cms/browser/content.phtml">
-                <block name="wysiwyg_images.uploader" type="adminhtml/cms_wysiwyg_images_content_uploader" template="cms/browser/content/uploader.phtml" />
+                <block name="wysiwyg_images.uploader" type="adminhtml/cms_wysiwyg_images_content_uploader" template="media/uploader.phtml">
+                    <block name="additional_scripts" type="core/template" template="cms/browser/content/uploader.phtml"/>
+                </block>
                 <block name="wysiwyg_images.newfolder" type="adminhtml/cms_wysiwyg_images_content_newfolder" template="cms/browser/content/newfolder.phtml" />
             </block>
         </reference>
diff --git app/design/adminhtml/default/default/layout/main.xml app/design/adminhtml/default/default/layout/main.xml
index d595d0d..fac12b9 100644
--- app/design/adminhtml/default/default/layout/main.xml
+++ app/design/adminhtml/default/default/layout/main.xml
@@ -171,9 +171,10 @@ Layout for editor element
             <action method="setCanLoadExtJs"><flag>1</flag></action>
             <action method="addJs"><script>mage/adminhtml/variables.js</script></action>
             <action method="addJs"><script>mage/adminhtml/wysiwyg/widget.js</script></action>
-            <action method="addJs"><script>lib/flex.js</script></action>
-            <action method="addJs"><script>lib/FABridge.js</script></action>
-            <action method="addJs"><script>mage/adminhtml/flexuploader.js</script></action>
+            <action method="addJs"><name>lib/uploader/flow.min.js</name></action>
+            <action method="addJs"><name>lib/uploader/fusty-flow.js</name></action>
+            <action method="addJs"><name>lib/uploader/fusty-flow-factory.js</name></action>
+            <action method="addJs"><name>mage/adminhtml/uploader/instance.js</name></action>
             <action method="addJs"><script>mage/adminhtml/browser.js</script></action>
             <action method="addJs"><script>prototype/window.js</script></action>
             <action method="addItem"><type>js_css</type><name>prototype/windows/themes/default.css</name></action>
diff --git app/design/adminhtml/default/default/layout/xmlconnect.xml app/design/adminhtml/default/default/layout/xmlconnect.xml
index 336e691..b4bec3f 100644
--- app/design/adminhtml/default/default/layout/xmlconnect.xml
+++ app/design/adminhtml/default/default/layout/xmlconnect.xml
@@ -75,9 +75,10 @@
             <action method="setCanLoadExtJs"><flag>1</flag></action>
             <action method="addJs"><script>mage/adminhtml/variables.js</script></action>
             <action method="addJs"><script>mage/adminhtml/wysiwyg/widget.js</script></action>
-            <action method="addJs"><script>lib/flex.js</script></action>
-            <action method="addJs"><script>lib/FABridge.js</script></action>
-            <action method="addJs"><script>mage/adminhtml/flexuploader.js</script></action>
+             <action method="addJs"><name>lib/uploader/flow.min.js</name></action>
+             <action method="addJs"><name>lib/uploader/fusty-flow.js</name></action>
+             <action method="addJs"><name>lib/uploader/fusty-flow-factory.js</name></action>
+             <action method="addJs"><name>mage/adminhtml/uploader/instance.js</name></action>
             <action method="addJs"><script>mage/adminhtml/browser.js</script></action>
             <action method="addJs"><script>prototype/window.js</script></action>
             <action method="addItem"><type>js_css</type><name>prototype/windows/themes/default.css</name></action>
@@ -104,7 +105,6 @@
                 <block type="xmlconnect/adminhtml_mobile_edit_tab_offlineCatalog" name="mobile_edit_tab_offlineCatalog"/>
                 <block type="xmlconnect/adminhtml_mobile_edit_tab_general" name="mobile_edit_tab_general"/>
                 <block type="xmlconnect/adminhtml_mobile_edit_tab_design" name="mobile_edit_tab_design">
-                    <block type="adminhtml/media_uploader" name="adminhtml_media_uploader" as="media_uploader"/>
                     <block type="xmlconnect/adminhtml_mobile_edit_tab_design_images" name="mobile_edit_tab_design_images" as="design_images" />
                     <block type="xmlconnect/adminhtml_mobile_edit_tab_design_accordion" name="mobile_edit_tab_design_accordion" as="design_accordion">
                         <block type="xmlconnect/adminhtml_mobile_edit_tab_design_accordion_themes" name="accordion_themes" />
diff --git app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
index 70d372a..0acfaac 100644
--- app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
+++ app/design/adminhtml/default/default/template/catalog/product/helper/gallery.phtml
@@ -108,6 +108,7 @@ $_block = $this;
     <tfoot>
         <tr>
             <td colspan="100" class="last" style="padding:8px">
+                <?php echo Mage::helper('catalog')->__('Maximum width and height dimension for upload image is %s.', Mage::getStoreConfig(Mage_Catalog_Helper_Image::XML_NODE_PRODUCT_MAX_DIMENSION)); ?>
                 <?php echo $_block->getUploaderHtml() ?>
             </td>
         </tr>
@@ -120,6 +121,6 @@ $_block = $this;
 <input type="hidden" id="<?php echo $_block->getHtmlId() ?>_save_image" name="<?php echo $_block->getElement()->getName() ?>[values]" value="<?php echo $_block->escapeHtml($_block->getImagesValuesJson()) ?>" />
 <script type="text/javascript">
 //<![CDATA[
-var <?php echo $_block->getJsObjectName(); ?> = new Product.Gallery('<?php echo $_block->getHtmlId() ?>', <?php if ($_block->getElement()->getReadonly()):?>null<?php else:?><?php echo $_block->getUploader()->getJsObjectName() ?><?php endif;?>, <?php echo $_block->getImageTypesJson() ?>);
+var <?php echo $_block->getJsObjectName(); ?> = new Product.Gallery('<?php echo $_block->getHtmlId() ?>', <?php echo $_block->getImageTypesJson() ?>);
 //]]>
 </script>
diff --git app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml
index c3d80f3..a1930ec 100644
--- app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml
+++ app/design/adminhtml/default/default/template/cms/browser/content/uploader.phtml
@@ -24,48 +24,8 @@
  * @license http://www.magento.com/license/enterprise-edition
  */
 ?>
-<?php
-/**
- * Uploader template for Wysiwyg Images
- *
- * @see Mage_Adminhtml_Block_Cms_Wysiwyg_Images_Content_Uploader
- */
-?>
-<div id="<?php echo $this->getHtmlId() ?>" class="uploader">
-    <div class="buttons">
-        <div id="<?php echo $this->getHtmlId() ?>-install-flash" style="display:none">
-            <?php echo Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/') ?>
-        </div>
-    </div>
-    <div class="clear"></div>
-    <div class="no-display" id="<?php echo $this->getHtmlId() ?>-template">
-        <div id="{{id}}" class="file-row">
-        <span class="file-info">{{name}} ({{size}})</span>
-        <span class="delete-button"><?php echo $this->getDeleteButtonHtml() ?></span>
-        <span class="progress-text"></span>
-        <div class="clear"></div>
-        </div>
-    </div>
-    <div class="no-display" id="<?php echo $this->getHtmlId() ?>-template-progress">
-        {{percent}}% {{uploaded}} / {{total}}
-    </div>
-</div>
-
 <script type="text/javascript">
 //<![CDATA[
-maxUploadFileSizeInBytes = <?php echo $this->getDataMaxSizeInBytes() ?>;
-maxUploadFileSize = '<?php echo $this->getDataMaxSize() ?>';
-
-<?php echo $this->getJsObjectName() ?> = new Flex.Uploader('<?php echo $this->getHtmlId() ?>', '<?php echo $this->getUploaderUrl('media/uploader.swf') ?>', <?php echo $this->getConfigJson() ?>);
-<?php echo $this->getJsObjectName() ?>.onFilesComplete = function(completedFiles){
-    completedFiles.each(function(file){
-        <?php echo $this->getJsObjectName() ?>.removeFile(file.id);
-    });
-    MediabrowserInstance.handleUploadComplete();
-}
-// hide flash buttons
-if ($('<?php echo $this->getHtmlId() ?>-flash') != undefined) {
-    $('<?php echo $this->getHtmlId() ?>-flash').setStyle({float:'left'});
-}
+    document.on('uploader:success', MediabrowserInstance.handleUploadComplete.bind(MediabrowserInstance));
 //]]>
 </script>
diff --git app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable.phtml app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable.phtml
index 2528b66..06edd0f 100644
--- app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable.phtml
@@ -34,19 +34,16 @@
 //<![CDATA[>
 
 var uploaderTemplate = '<div class="no-display" id="[[idName]]-template">' +
-                            '<div id="{{id}}" class="file-row file-row-narrow">' +
+                            '<div id="{{id}}-container" class="file-row file-row-narrow">' +
                                 '<span class="file-info">' +
                                     '<span class="file-info-name">{{name}}</span>' +
                                     ' ' +
-                                    '<span class="file-info-size">({{size}})</span>' +
+                                    '<span class="file-info-size">{{size}}</span>' +
                                 '</span>' +
                                 '<span class="progress-text"></span>' +
                                 '<div class="clear"></div>' +
                             '</div>' +
-                        '</div>' +
-                            '<div class="no-display" id="[[idName]]-template-progress">' +
-                            '{{percent}}% {{uploaded}} / {{total}}' +
-                            '</div>';
+                        '</div>';
 
 var fileListTemplate = '<span class="file-info">' +
                             '<span class="file-info-name">{{name}}</span>' +
@@ -88,7 +85,7 @@ var Downloadable = {
     massUploadByType : function(type){
         try {
             this.uploaderObj.get(type).each(function(item){
-                container = item.value.container.up('tr');
+                var container = item.value.elements.container.up('tr');
                 if (container.visible() && !container.hasClassName('no-display')) {
                     item.value.upload();
                 } else {
@@ -141,10 +138,11 @@ Downloadable.FileUploader.prototype = {
                ? this.fileValue.toJSON()
                : Object.toJSON(this.fileValue);
         }
+        var uploaderConfig = (Object.isString(this.config) && this.config.evalJSON()) || this.config;
         Downloadable.setUploaderObj(
             this.type,
             this.key,
-            new Flex.Uploader(this.idName, '<?php echo $this->getSkinUrl('media/uploaderSingle.swf') ?>', this.config)
+            new Uploader(uploaderConfig)
         );
         if (varienGlobalEvents) {
             varienGlobalEvents.attachEventHandler('tabChangeBefore', Downloadable.getUploaderObj(type, key).onContainerHideBefore);
@@ -167,16 +165,48 @@ Downloadable.FileList.prototype = {
         this.containerId  = containerId,
         this.container = $(this.containerId);
         this.uploader = uploader;
-        this.uploader.onFilesComplete = this.handleUploadComplete.bind(this);
+        document.on('uploader:fileSuccess', function(event) {
+            var memo = event.memo;
+            if(this._checkCurrentContainer(memo.containerId)) {
+                this.handleUploadComplete([{response: memo.response}]);
+                this.handleButtonsSwap();
+            }
+        }.bind(this));
+        document.on('uploader:fileError', function(event) {
+            var memo = event.memo;
+            if(this._checkCurrentContainer(memo.containerId)) {
+                this.handleButtonsSwap();
+            }
+        }.bind(this));
+        document.on('upload:simulateDelete', this.handleFileRemoveAll.bind(this));
+        document.on('uploader:simulateNewUpload', this.handleFileNew.bind(this));
         this.file = this.getElement('save').value.evalJSON();
         this.listTemplate = new Template(this.fileListTemplate, this.templatePattern);
         this.updateFiles();
         this.uploader.onFileRemoveAll = this.handleFileRemoveAll.bind(this);
         this.uploader.onFileSelect = this.handleFileSelect.bind(this);
     },
-    handleFileRemoveAll: function(fileId) {
-        $(this.containerId+'-new').hide();
-        $(this.containerId+'-old').show();
+
+    _checkCurrentContainer: function (child) {
+        return $(this.containerId).down('#' + child);
+    },
+
+    handleFileRemoveAll: function(e) {
+        if(e.memo && this._checkCurrentContainer(e.memo.containerId)) {
+            $(this.containerId+'-new').hide();
+            $(this.containerId+'-old').show();
+            this.handleButtonsSwap();
+        }
+    },
+    handleFileNew: function (e) {
+        if(e.memo && this._checkCurrentContainer(e.memo.containerId)) {
+            $(this.containerId + '-new').show();
+            $(this.containerId + '-old').hide();
+            this.handleButtonsSwap();
+        }
+    },
+    handleButtonsSwap: function () {
+        $$(['#' + this.containerId+'-browse', '#'+this.containerId+'-delete']).invoke('toggle');
     },
     handleFileSelect: function() {
         $(this.containerId+'_type').checked = true;
@@ -204,7 +234,6 @@ Downloadable.FileList.prototype = {
            newFile.size = response.size;
            newFile.status = 'new';
            this.file[0] = newFile;
-           this.uploader.removeFile(item.id);
         }.bind(this));
         this.updateFiles();
     },
diff --git app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
index 06c939e..36b3b1f 100644
--- app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/links.phtml
@@ -28,6 +28,7 @@
 
 /**
  * @see Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Links
+ * @var $this Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Links
  */
 ?>
 <?php $_product = $this->getProduct()?>
@@ -137,17 +138,14 @@ var linkTemplate = '<tr>'+
     '</td>'+
     '<td>'+
         '<div class="files">'+
-            '<div class="row">'+
-                '<label for="downloadable_link_{{id}}_sample_file_type"><input type="radio" class="radio" id="downloadable_link_{{id}}_sample_file_type" name="downloadable[link][{{id}}][sample][type]" value="file"{{sample_file_checked}} /> File:</label>'+
+            '<div class="row a-right">'+
+                '<label for="downloadable_link_{{id}}_sample_file_type" class="a-left"><input type="radio" class="radio" id="downloadable_link_{{id}}_sample_file_type" name="downloadable[link][{{id}}][sample][type]" value="file"{{sample_file_checked}} /> File:</label>'+
                 '<input type="hidden" id="downloadable_link_{{id}}_sample_file_save" name="downloadable[link][{{id}}][sample][file]" value="{{sample_file_save}}" />'+
-                '<div id="downloadable_link_{{id}}_sample_file" class="uploader">'+
+                '<?php echo $this->getBrowseButtonHtml('sample_'); ?>'+
+                '<?php echo $this->getDeleteButtonHtml('sample_'); ?>'+
+                '<div id="downloadable_link_{{id}}_sample_file" class="uploader a-left">'+
                     '<div id="downloadable_link_{{id}}_sample_file-old" class="file-row-info"></div>'+
                     '<div id="downloadable_link_{{id}}_sample_file-new" class="file-row-info"></div>'+
-                    '<div class="buttons">'+
-                        '<div id="downloadable_link_{{id}}_sample_file-install-flash" style="display:none">'+
-                            '<?php echo $this->jsQuoteEscape(Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/')) ?>'+
-                        '</div>'+
-                    '</div>'+
                     '<div class="clear"></div>'+
                 '</div>'+
             '</div>'+
@@ -161,17 +159,14 @@ var linkTemplate = '<tr>'+
     '</td>'+
     '<td>'+
         '<div class="files">'+
-            '<div class="row">'+
-                '<label for="downloadable_link_{{id}}_file_type"><input type="radio" class="radio validate-one-required-by-name" id="downloadable_link_{{id}}_file_type" name="downloadable[link][{{id}}][type]" value="file"{{file_checked}} /> File:</label>'+
+            '<div class="row a-right">'+
+                '<label for="downloadable_link_{{id}}_file_type" class="a-left"><input type="radio" class="radio validate-one-required-by-name" id="downloadable_link_{{id}}_file_type" name="downloadable[link][{{id}}][type]" value="file"{{file_checked}} /> File:</label>'+
             '<input type="hidden" class="validate-downloadable-file" id="downloadable_link_{{id}}_file_save" name="downloadable[link][{{id}}][file]" value="{{file_save}}" />'+
-                '<div id="downloadable_link_{{id}}_file" class="uploader">'+
+                '<?php echo $this->getBrowseButtonHtml(); ?>'+
+                '<?php echo $this->getDeleteButtonHtml(); ?>'+
+                '<div id="downloadable_link_{{id}}_file" class="uploader a-left">'+
                     '<div id="downloadable_link_{{id}}_file-old" class="file-row-info"></div>'+
                     '<div id="downloadable_link_{{id}}_file-new" class="file-row-info new-file"></div>'+
-                    '<div class="buttons">'+
-                        '<div id="downloadable_link_{{id}}_file-install-flash" style="display:none">'+
-                            '<?php echo $this->jsQuoteEscape(Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/')) ?>'+
-                        '</div>'+
-                    '</div>'+
                     '<div class="clear"></div>'+
                 '</div>'+
             '</div>'+
@@ -282,6 +277,9 @@ var linkItems = {
         if (!data.sample_file_save) {
             data.sample_file_save = [];
         }
+        var UploaderConfigLinkSamples = <?php echo $this->getConfigJson('link_samples') ?>.replace(
+            new RegExp('<?php echo $this->getId(); ?>', 'g'),
+            'downloadable_link_'+data.id+'_sample_file');
 
         // link sample file
         new Downloadable.FileUploader(
@@ -291,8 +289,12 @@ var linkItems = {
             'downloadable[link]['+data.id+'][sample]',
             data.sample_file_save,
             'downloadable_link_'+data.id+'_sample_file',
-            <?php echo $this->getConfigJson('link_samples') ?>
+            UploaderConfigLinkSamples
         );
+
+        var UploaderConfigLink = <?php echo $this->getConfigJson() ?>.replace(
+            new RegExp('<?php echo $this->getId(); ?>', 'g'),
+            'downloadable_link_'+data.id+'_file');
         // link file
         new Downloadable.FileUploader(
             'links',
@@ -301,7 +303,7 @@ var linkItems = {
             'downloadable[link]['+data.id+']',
             data.file_save,
             'downloadable_link_'+data.id+'_file',
-            <?php echo $this->getConfigJson() ?>
+            UploaderConfigLink
         );
 
         linkFile = $('downloadable_link_'+data.id+'_file_type');
diff --git app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/samples.phtml app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/samples.phtml
index 7d90258..7de7059 100644
--- app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/samples.phtml
+++ app/design/adminhtml/default/default/template/downloadable/product/edit/downloadable/samples.phtml
@@ -27,6 +27,7 @@
 <?php
 /**
  * @see Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Samples
+ * @var $this Mage_Downloadable_Block_Adminhtml_Catalog_Product_Edit_Tab_Downloadable_Samples
  */
 ?>
 
@@ -89,17 +90,14 @@ var sampleTemplate = '<tr>'+
                         '</td>'+
                         '<td>'+
                             '<div class="files-wide">'+
-                                '<div class="row">'+
-                                    '<label for="downloadable_sample_{{id}}_file_type"><input type="radio" class="radio validate-one-required-by-name" id="downloadable_sample_{{id}}_file_type" name="downloadable[sample][{{id}}][type]" value="file"{{file_checked}} /> File:</label>'+
+                                '<div class="row a-right">'+
+                                    '<label for="downloadable_sample_{{id}}_file_type" class="a-left"><input type="radio" class="radio validate-one-required-by-name" id="downloadable_sample_{{id}}_file_type" name="downloadable[sample][{{id}}][type]" value="file"{{file_checked}} /> File:</label>'+
                                     '<input type="hidden" class="validate-downloadable-file" id="downloadable_sample_{{id}}_file_save" name="downloadable[sample][{{id}}][file]" value="{{file_save}}" />'+
-                                    '<div id="downloadable_sample_{{id}}_file" class="uploader">'+
+                                    '<?php echo $this->getBrowseButtonHtml(); ?>'+
+                                    '<?php echo $this->getDeleteButtonHtml(); ?>'+
+                                    '<div id="downloadable_sample_{{id}}_file" class="uploader a-left">' +
                                         '<div id="downloadable_sample_{{id}}_file-old" class="file-row-info"></div>'+
                                         '<div id="downloadable_sample_{{id}}_file-new" class="file-row-info new-file"></div>'+
-                                        '<div class="buttons">'+
-                                            '<div id="downloadable_sample_{{id}}_file-install-flash" style="display:none">'+
-                                                '<?php echo $this->jsQuoteEscape(Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/')) ?>'+
-                                            '</div>'+
-                                        '</div>'+
                                         '<div class="clear"></div>'+
                                     '</div>'+
                                 '</div>'+
@@ -161,6 +159,10 @@ var sampleItems = {
 
         sampleUrl = $('downloadable_sample_'+data.id+'_url_type');
 
+        var UploaderConfig = <?php echo $this->getConfigJson() ?>.replace(
+            new RegExp('<?php echo $this->getId(); ?>', 'g'),
+            'downloadable_sample_'+data.id+'_file');
+
         if (!data.file_save) {
             data.file_save = [];
         }
@@ -171,7 +173,7 @@ var sampleItems = {
             'downloadable[sample]['+data.id+']',
             data.file_save,
             'downloadable_sample_'+data.id+'_file',
-            <?php echo $this->getConfigJson() ?>
+            UploaderConfig
         );
         sampleUrl.advaiceContainer = 'downloadable_sample_'+data.id+'_container';
         sampleFile = $('downloadable_sample_'+data.id+'_file_type');
diff --git app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml
index 9cdbdff..c4cbcac 100644
--- app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml
+++ app/design/adminhtml/default/default/template/enterprise/invitation/view/tab/general.phtml
@@ -66,7 +66,7 @@
                 <td class="label"><label><?php  echo $this->helper('enterprise_invitation')->__('Email'); ?><?php if ($this->canEditMessage()): ?><span class="required">*</span><?php endif; ?></label></td>
                 <td>
                 <?php if ($this->canEditMessage()): ?>
-                    <input type="text" class="required-entry input-text validate-email" name="email" value="<?php echo $this->getInvitation()->getEmail() ?>" />
+                    <input type="text" class="required-entry input-text validate-email" name="email" value="<?php echo $this->escapeHtml($this->getInvitation()->getEmail()) ?>" />
                 <?php else: ?>
                     <strong><?php echo $this->escapeHtml($this->getInvitation()->getEmail()) ?></strong>
                 <?php endif; ?>
diff --git app/design/adminhtml/default/default/template/media/uploader.phtml app/design/adminhtml/default/default/template/media/uploader.phtml
index 2ff40e7..b591c42 100644
--- app/design/adminhtml/default/default/template/media/uploader.phtml
+++ app/design/adminhtml/default/default/template/media/uploader.phtml
@@ -26,48 +26,30 @@
 ?>
 <?php
 /**
- * @see Mage_Adminhtml_Block_Media_Uploader
+ * @var $this Mage_Uploader_Block_Multiple|Mage_Uploader_Block_Single
  */
 ?>
-
-<?php echo $this->helper('adminhtml/js')->includeScript('lib/flex.js') ?>
-<?php echo $this->helper('adminhtml/js')->includeScript('mage/adminhtml/flexuploader.js') ?>
-<?php echo $this->helper('adminhtml/js')->includeScript('lib/FABridge.js') ?>
-
 <div id="<?php echo $this->getHtmlId() ?>" class="uploader">
-    <div class="buttons">
-        <?php /* buttons included in flex object */ ?>
-        <?php  /*echo $this->getBrowseButtonHtml()*/  ?>
-        <?php  /*echo $this->getUploadButtonHtml()*/  ?>
-        <div id="<?php echo $this->getHtmlId() ?>-install-flash" style="display:none">
-            <?php echo Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/') ?>
-        </div>
+    <div class="buttons a-right">
+        <?php echo $this->getBrowseButtonHtml(); ?>
+        <?php echo $this->getUploadButtonHtml(); ?>
     </div>
-    <div class="clear"></div>
-    <div class="no-display" id="<?php echo $this->getHtmlId() ?>-template">
-        <div id="{{id}}" class="file-row">
-        <span class="file-info">{{name}} ({{size}})</span>
+</div>
+<div class="no-display" id="<?php echo $this->getElementId('template') ?>">
+    <div id="{{id}}-container" class="file-row">
+        <span class="file-info">{{name}} {{size}}</span>
         <span class="delete-button"><?php echo $this->getDeleteButtonHtml() ?></span>
         <span class="progress-text"></span>
         <div class="clear"></div>
-        </div>
-    </div>
-    <div class="no-display" id="<?php echo $this->getHtmlId() ?>-template-progress">
-        {{percent}}% {{uploaded}} / {{total}}
     </div>
 </div>
-
 <script type="text/javascript">
-//<![CDATA[
-
-var maxUploadFileSizeInBytes = <?php echo $this->getDataMaxSizeInBytes() ?>;
-var maxUploadFileSize = '<?php echo $this->getDataMaxSize() ?>';
-
-<?php echo $this->getJsObjectName() ?> = new Flex.Uploader('<?php echo $this->getHtmlId() ?>', '<?php echo $this->getUploaderUrl('media/uploader.swf') ?>', <?php echo $this->getConfigJson() ?>);
-
-if (varienGlobalEvents) {
-    varienGlobalEvents.attachEventHandler('tabChangeBefore', <?php echo $this->getJsObjectName() ?>.onContainerHideBefore);
-}
+    (function() {
+        var uploader = new Uploader(<?php echo $this->getJsonConfig(); ?>);
 
-//]]>
+        if (varienGlobalEvents) {
+            varienGlobalEvents.attachEventHandler('tabChangeBefore', uploader.onContainerHideBefore);
+        }
+    })();
 </script>
+<?php echo $this->getChildHtml('additional_scripts'); ?>
diff --git app/design/adminhtml/default/default/template/xmlconnect/edit/tab/design.phtml app/design/adminhtml/default/default/template/xmlconnect/edit/tab/design.phtml
index d489452..d0528e5 100644
--- app/design/adminhtml/default/default/template/xmlconnect/edit/tab/design.phtml
+++ app/design/adminhtml/default/default/template/xmlconnect/edit/tab/design.phtml
@@ -24,19 +24,22 @@
  * @license http://www.magento.com/license/enterprise-edition
  */
 ?>
+<?php
+/**
+ * @var $this Mage_XmlConnect_Block_Adminhtml_Mobile_Edit_Tab_Design
+ */
+?>
 <script type="text/javascript">
 // <![CDATA[
 var imageTemplate = '<input type="hidden" name="{{file_field}}[image][{{id}}][image_id]" value="{{image_id}}" />'+
         '<div class="banner-image">'+
-            '<div class="row">'+
-                '<div id="{{file_field}}_{{id}}_file" class="uploader">'+
+            '<div class="row a-right">' +
+                '<div class="flex">' +
+                '<?php echo $this->getBrowseButtonHtml() ?>'+
+                '</div>' +
+                '<div id="{{file_field}}_{{id}}_file" class="uploader a-left">'+
                     '<div id="{{file_field}}_{{id}}_file-old" class="file-row-info"><div id="{{file_field}}_preview_{{id}}" style="background:url({{thumbnail}}) no-repeat center;" class="image-placeholder"></div></div>'+
                     '<div id="{{file_field}}_{{id}}_file-new" class="file-row-info new-file"></div>'+
-                    '<div class="buttons">'+
-                        '<div id="{{file_field}}_{{id}}_file-install-flash" style="display:none">'+
-                            '<?php echo $this->jsQuoteEscape(Mage::helper('media')->__('This content requires last version of Adobe Flash Player. <a href="%s">Get Flash</a>', 'http://www.adobe.com/go/getflash/')) ?>'+
-                        '</div>'+
-                    '</div>'+
                     '<div class="clear"></div>'+
                 '</div>'+
             '</div>'+
@@ -66,6 +69,16 @@ var imageItems = {
     imageActionTruncateLenght: 35,
     add : function(config) {
         try {
+            if(Object.isString(config)) {
+                config = config.evalJSON();
+            }
+            config.file_field = config.uploaderConfig.fileParameterName;
+            config.file_save = config.miscConfig.file_save;
+            config.thumbnail = config.miscConfig.thumbnail;
+            config.image_id = config.miscConfig.image_id;
+            config.image_action_data = config.miscConfig.image_action_data;
+            config.image_count = config.miscConfig.image_count;
+
             var isUploadedImage = true, uploaderClass = '';
             this.template = new Template(this.templateText, this.templateSyntax);
 
@@ -89,7 +102,11 @@ var imageItems = {
             Element.insert(this.ulImages.down('li', config.id), {'bottom' : this.template.evaluate(config)});
             var container = $(config.file_field + '_' + config.id + '_file').up('li');
 
-            if (config.show_uploader == 1) {
+            if (config.image_id != 'uploader') {
+                container.down('.flex').remove();
+                imageItems.addEditButton(container, config);
+                imageItems.addDeleteButton(container, config);
+            } else {
                 config.file_save = [];
 
                 new Downloadable.FileUploader(
@@ -102,11 +119,6 @@ var imageItems = {
                     config
                 );
             }
-
-            if (config.image_id != 'uploader') {
-                imageItems.addEditButton(container, config);
-                imageItems.addDeleteButton(container, config);
-            }
         } catch (e) {
             alert(e.message);
         }
@@ -209,7 +221,10 @@ var imageItems = {
     },
     reloadImages : function(image_list) {
         try {
-            var imageType = image_list[0].file_field;
+            image_list = image_list.map(function (item) {
+                return Object.isString(item) ? item.evalJSON(): item;
+            });
+            var imageType = image_list[0].uploaderConfig.fileParameterName;
             Downloadable.unsetUploaderByType(imageType);
             var currentContainerId = imageType;
             var currentContainer = $(currentContainerId);
@@ -283,28 +298,18 @@ var imageItems = {
 
 jscolor.dir = '<?php echo $this->getJsUrl(); ?>jscolor/';
 
-var maxUploadFileSizeInBytes = <?php echo $this->getChild('media_uploader')->getDataMaxSizeInBytes() ?>;
-var maxUploadFileSize = '<?php echo $this->getChild('media_uploader')->getDataMaxSize() ?>';
-
 var uploaderTemplate = '<div class="no-display" id="[[idName]]-template">' +
-                            '<div id="{{id}}" class="file-row file-row-narrow">' +
+                            '<div id="{{id}}-container" class="file-row file-row-narrow">' +
                                 '<span class="file-info">' +
                                     '<span class="file-info-name">{{name}}</span>' + ' ' +
-                                    '<span class="file-info-size">({{size}})</span>' +
+                                    '<span class="file-info-size">{{size}}</span>' +
                                 '</span>' +
                                 '<span class="progress-text"></span>' +
                                 '<div class="clear"></div>' +
                             '</div>' +
-                        '</div>' +
-                        '<div class="no-display" id="[[idName]]-template-progress">' +
-                            '{{percent}}% {{uploaded}} / {{total}}' +
                         '</div>';
 
-var fileListTemplate = '<div style="background:url({{file}}) no-repeat center;" class="image-placeholder"></div>' +
-                        '<span class="file-info">' +
-                            '<span class="file-info-name">{{name}}</span>' + ' ' +
-                            '<span class="file-info-size">({{size}})</span>' +
-                        '</span>';
+var fileListTemplate = '<div style="background:url({{file}}) no-repeat center;" class="image-placeholder"></div>';
 
 var Downloadable = {
     uploaderObj : $H({}),
@@ -401,13 +406,17 @@ Downloadable.FileUploader.prototype = {
         if ($(this.idName + '_save')) {
             $(this.idName + '_save').value = this.fileValue.toJSON ? this.fileValue.toJSON() : Object.toJSON(this.fileValue);
         }
+
+        this.config = Object.toJSON(this.config).replace(
+            new RegExp(config.elementIds.idToReplace, 'g'),
+            config.file_field + '_'+ config.id + '_file').evalJSON();
+
         Downloadable.setUploaderObj(
             this.type,
             this.key,
-            new Flex.Uploader(this.idName, '<?php echo $this->getSkinUrl('media/uploaderSingle.swf') ?>', this.config)
+            new Uploader(this.config)
         );
         new Downloadable.FileList(this.idName, Downloadable.getUploaderObj(type, key), this.config);
-
         if (varienGlobalEvents) {
             varienGlobalEvents.attachEventHandler('tabChangeBefore', Downloadable.getUploaderObj(type, key).onContainerHideBefore);
         }
@@ -427,35 +436,34 @@ Downloadable.FileList.prototype = {
         this.containerId  = containerId,
         this.container = $(this.containerId);
         this.uploader = uploader;
-        this.uploader.onFilesComplete = this.handleUploadComplete.bind(this);
+        this.uploader.uploader.on('filesSubmitted', this.handleFileSelect.bind(this));
+        document.on('uploader:fileSuccess', function(event) {
+            var memo = event.memo;
+            if(this._checkCurrentContainer(memo.containerId)) {
+                this.handleUploadComplete([{response: memo.response}]);
+            }
+        }.bind(this));
         this.file = this.getElement('save').value.evalJSON();
         this.listTemplate = new Template(this.fileListTemplate, this.templatePattern);
         this.updateFiles();
-        this.uploader.handleSelect = this.handleFileSelect.bind(this);
-        this.uploader.onContainerHideBefore = this.handleContainerHideBefore.bind(this);
         this.uploader.config = config;
-    },
-    handleContainerHideBefore: function(container) {
-        if (container && Element.descendantOf(this.uploader.container, container) && !this.uploader.checkAllComplete()) {
-            if (!confirm('<?php echo $this->jsQuoteEscape($this->__('There are files that were selected but not uploaded yet. After switching to another tab your selections may be lost. Do you wish to continue ?')) ;?>')) {
-                return 'cannotchange';
-            } else {
+        this.onContainerHideBefore = this.uploader.onContainerHideBefore.bind(
+            this.uploader,
+            function () {
                 return 'change';
-            }
-        }
+            });
+    },
+    _checkCurrentContainer: function (child) {
+        return $(this.containerId).down('#' + child);
     },
     handleFileSelect: function(event) {
         try {
-            this.uploader.files = event.getData().files;
-            this.uploader.checkFileSize();
-            this.updateFiles();
-            if (!hasTooBigFiles) {
-                var uploaderList = $(this.uploader.flexContainerId);
-                for (i = 0; i < uploaderList.length; i++) {
-                    uploaderList[i].setStyle({visibility: 'hidden'});
-                }
-                Downloadable.massUploadByType(this.uploader.config.file_field);
+            if(this.uploader.uploader.files.length) {
+                $(this.containerId + '-old').hide();
+                this.uploader.elements.browse.invoke('setStyle', {'visibility': 'hidden'});
             }
+            this.updateFiles();
+            Downloadable.massUploadByType(this.uploader.config.file_field);
         } catch (e) {
             alert(e.message);
         }
@@ -485,7 +493,6 @@ Downloadable.FileList.prototype = {
                 newFile.size = response.size;
                 newFile.status = 'new';
                 this.file[0] = newFile;
-                this.uploader.removeFile(item.id);
                 imageItems.reloadImages(response.image_list);
             }.bind(this));
             this.updateFiles();
diff --git app/etc/modules/Mage_All.xml app/etc/modules/Mage_All.xml
index 2a82d56..c028178 100644
--- app/etc/modules/Mage_All.xml
+++ app/etc/modules/Mage_All.xml
@@ -275,7 +275,7 @@
             <active>true</active>
             <codePool>core</codePool>
             <depends>
-                <Mage_Core/>
+                <Mage_Uploader/>
             </depends>
         </Mage_Cms>
         <Mage_Reports>
@@ -397,5 +397,12 @@
                 <Mage_Core/>
             </depends>
         </Mage_Index>
+        <Mage_Uploader>
+            <active>true</active>
+            <codePool>core</codePool>
+            <depends>
+                <Mage_Core/>
+            </depends>
+        </Mage_Uploader>
     </modules>
 </config>
diff --git app/locale/en_US/Mage_Media.csv app/locale/en_US/Mage_Media.csv
index 110331b..504a44a 100644
--- app/locale/en_US/Mage_Media.csv
+++ app/locale/en_US/Mage_Media.csv
@@ -1,3 +1,2 @@
 "An error occurred while creating the image.","An error occurred while creating the image."
 "The image does not exist or is invalid.","The image does not exist or is invalid."
-"This content requires last version of Adobe Flash Player. <a href=""%s"">Get Flash</a>","This content requires last version of Adobe Flash Player. <a href=""%s"">Get Flash</a>"
diff --git app/locale/en_US/Mage_Uploader.csv app/locale/en_US/Mage_Uploader.csv
new file mode 100644
index 0000000..c246b24
--- /dev/null
+++ app/locale/en_US/Mage_Uploader.csv
@@ -0,0 +1,8 @@
+"Browse Files...","Browse Files..."
+"Upload Files","Upload Files"
+"Remove", "Remove"
+"There are files that were selected but not uploaded yet. After switching to another tab your selections will be lost. Do you wish to continue ?", "There are files that were selected but not uploaded yet. After switching to another tab your selections will be lost. Do you wish to continue ?"
+"Maximum allowed file size for upload is","Maximum allowed file size for upload is"
+"Please check your server PHP settings.","Please check your server PHP settings."
+"Uploading...","Uploading..."
+"Complete","Complete"
\ No newline at end of file
diff --git downloader/lib/Mage/HTTP/Client/Curl.php downloader/lib/Mage/HTTP/Client/Curl.php
index 2def3a4..68b7d86 100644
--- downloader/lib/Mage/HTTP/Client/Curl.php
+++ downloader/lib/Mage/HTTP/Client/Curl.php
@@ -373,7 +373,7 @@ implements Mage_HTTP_IClient
         $uriModified = $this->getModifiedUri($uri, $https);
         $this->_ch = curl_init();
         $this->curlOption(CURLOPT_URL, $uriModified);
-        $this->curlOption(CURLOPT_SSL_VERIFYPEER, false);
+        $this->curlOption(CURLOPT_SSL_VERIFYPEER, true);
         $this->curlOption(CURLOPT_SSL_CIPHER_LIST, 'TLSv1');
         $this->getCurlMethodSettings($method, $params, $isAuthorizationRequired);
 
diff --git js/lib/uploader/flow.min.js js/lib/uploader/flow.min.js
new file mode 100644
index 0000000..34b888e
--- /dev/null
+++ js/lib/uploader/flow.min.js
@@ -0,0 +1,2 @@
+/*! flow.js 2.9.0 */
+!function(a,b,c){"use strict";function d(b){if(this.support=!("undefined"==typeof File||"undefined"==typeof Blob||"undefined"==typeof FileList||!Blob.prototype.slice&&!Blob.prototype.webkitSlice&&!Blob.prototype.mozSlice),this.support){this.supportDirectory=/WebKit/.test(a.navigator.userAgent),this.files=[],this.defaults={chunkSize:1048576,forceChunkSize:!1,simultaneousUploads:3,singleFile:!1,fileParameterName:"file",progressCallbacksInterval:500,speedSmoothingFactor:.1,query:{},headers:{},withCredentials:!1,preprocess:null,method:"multipart",testMethod:"GET",uploadMethod:"POST",prioritizeFirstAndLastChunk:!1,target:"/",testChunks:!0,generateUniqueIdentifier:null,maxChunkRetries:0,chunkRetryInterval:null,permanentErrors:[404,415,500,501],successStatuses:[200,201,202],onDropStopPropagation:!1},this.opts={},this.events={};var c=this;this.onDrop=function(a){c.opts.onDropStopPropagation&&a.stopPropagation(),a.preventDefault();var b=a.dataTransfer;b.items&&b.items[0]&&b.items[0].webkitGetAsEntry?c.webkitReadDataTransfer(a):c.addFiles(b.files,a)},this.preventEvent=function(a){a.preventDefault()},this.opts=d.extend({},this.defaults,b||{})}}function e(a,b){this.flowObj=a,this.file=b,this.name=b.fileName||b.name,this.size=b.size,this.relativePath=b.relativePath||b.webkitRelativePath||this.name,this.uniqueIdentifier=a.generateUniqueIdentifier(b),this.chunks=[],this.paused=!1,this.error=!1,this.averageSpeed=0,this.currentSpeed=0,this._lastProgressCallback=Date.now(),this._prevUploadedSize=0,this._prevProgress=0,this.bootstrap()}function f(a,b,c){this.flowObj=a,this.fileObj=b,this.fileObjSize=b.size,this.offset=c,this.tested=!1,this.retries=0,this.pendingRetry=!1,this.preprocessState=0,this.loaded=0,this.total=0;var d=this.flowObj.opts.chunkSize;this.startByte=this.offset*d,this.endByte=Math.min(this.fileObjSize,(this.offset+1)*d),this.xhr=null,this.fileObjSize-this.endByte<d&&!this.flowObj.opts.forceChunkSize&&(this.endByte=this.fileObjSize);var e=this;this.event=function(a,b){b=Array.prototype.slice.call(arguments),b.unshift(e),e.fileObj.chunkEvent.apply(e.fileObj,b)},this.progressHandler=function(a){a.lengthComputable&&(e.loaded=a.loaded,e.total=a.total),e.event("progress",a)},this.testHandler=function(){var a=e.status(!0);"error"===a?(e.event(a,e.message()),e.flowObj.uploadNextChunk()):"success"===a?(e.tested=!0,e.event(a,e.message()),e.flowObj.uploadNextChunk()):e.fileObj.paused||(e.tested=!0,e.send())},this.doneHandler=function(){var a=e.status();if("success"===a||"error"===a)e.event(a,e.message()),e.flowObj.uploadNextChunk();else{e.event("retry",e.message()),e.pendingRetry=!0,e.abort(),e.retries++;var b=e.flowObj.opts.chunkRetryInterval;null!==b?setTimeout(function(){e.send()},b):e.send()}}}function g(a,b){var c=a.indexOf(b);c>-1&&a.splice(c,1)}function h(a,b){return"function"==typeof a&&(b=Array.prototype.slice.call(arguments),a=a.apply(null,b.slice(1))),a}function i(a,b){setTimeout(a.bind(b),0)}function j(a){return k(arguments,function(b){b!==a&&k(b,function(b,c){a[c]=b})}),a}function k(a,b,c){if(a){var d;if("undefined"!=typeof a.length){for(d=0;d<a.length;d++)if(b.call(c,a[d],d)===!1)return}else for(d in a)if(a.hasOwnProperty(d)&&b.call(c,a[d],d)===!1)return}}var l=a.navigator.msPointerEnabled;d.prototype={on:function(a,b){a=a.toLowerCase(),this.events.hasOwnProperty(a)||(this.events[a]=[]),this.events[a].push(b)},off:function(a,b){a!==c?(a=a.toLowerCase(),b!==c?this.events.hasOwnProperty(a)&&g(this.events[a],b):delete this.events[a]):this.events={}},fire:function(a,b){b=Array.prototype.slice.call(arguments),a=a.toLowerCase();var c=!1;return this.events.hasOwnProperty(a)&&k(this.events[a],function(a){c=a.apply(this,b.slice(1))===!1||c},this),"catchall"!=a&&(b.unshift("catchAll"),c=this.fire.apply(this,b)===!1||c),!c},webkitReadDataTransfer:function(a){function b(a){g+=a.length,k(a,function(a){if(a.isFile){var e=a.fullPath;a.file(function(a){c(a,e)},d)}else a.isDirectory&&a.createReader().readEntries(b,d)}),e()}function c(a,b){a.relativePath=b.substring(1),h.push(a),e()}function d(a){throw a}function e(){0==--g&&f.addFiles(h,a)}var f=this,g=a.dataTransfer.items.length,h=[];k(a.dataTransfer.items,function(a){var f=a.webkitGetAsEntry();return f?void(f.isFile?c(a.getAsFile(),f.fullPath):f.createReader().readEntries(b,d)):void e()})},generateUniqueIdentifier:function(a){var b=this.opts.generateUniqueIdentifier;if("function"==typeof b)return b(a);var c=a.relativePath||a.webkitRelativePath||a.fileName||a.name;return a.size+"-"+c.replace(/[^0-9a-zA-Z_-]/gim,"")},uploadNextChunk:function(a){var b=!1;if(this.opts.prioritizeFirstAndLastChunk&&(k(this.files,function(a){return!a.paused&&a.chunks.length&&"pending"===a.chunks[0].status()&&0===a.chunks[0].preprocessState?(a.chunks[0].send(),b=!0,!1):!a.paused&&a.chunks.length>1&&"pending"===a.chunks[a.chunks.length-1].status()&&0===a.chunks[0].preprocessState?(a.chunks[a.chunks.length-1].send(),b=!0,!1):void 0}),b))return b;if(k(this.files,function(a){return a.paused||k(a.chunks,function(a){return"pending"===a.status()&&0===a.preprocessState?(a.send(),b=!0,!1):void 0}),b?!1:void 0}),b)return!0;var c=!1;return k(this.files,function(a){return a.isComplete()?void 0:(c=!0,!1)}),c||a||i(function(){this.fire("complete")},this),!1},assignBrowse:function(a,c,d,e){"undefined"==typeof a.length&&(a=[a]),k(a,function(a){var f;"INPUT"===a.tagName&&"file"===a.type?f=a:(f=b.createElement("input"),f.setAttribute("type","file"),j(f.style,{visibility:"hidden",position:"absolute"}),a.appendChild(f),a.addEventListener("click",function(){f.click()},!1)),this.opts.singleFile||d||f.setAttribute("multiple","multiple"),c&&f.setAttribute("webkitdirectory","webkitdirectory"),k(e,function(a,b){f.setAttribute(b,a)});var g=this;f.addEventListener("change",function(a){g.addFiles(a.target.files,a),a.target.value=""},!1)},this)},assignDrop:function(a){"undefined"==typeof a.length&&(a=[a]),k(a,function(a){a.addEventListener("dragover",this.preventEvent,!1),a.addEventListener("dragenter",this.preventEvent,!1),a.addEventListener("drop",this.onDrop,!1)},this)},unAssignDrop:function(a){"undefined"==typeof a.length&&(a=[a]),k(a,function(a){a.removeEventListener("dragover",this.preventEvent),a.removeEventListener("dragenter",this.preventEvent),a.removeEventListener("drop",this.onDrop)},this)},isUploading:function(){var a=!1;return k(this.files,function(b){return b.isUploading()?(a=!0,!1):void 0}),a},_shouldUploadNext:function(){var a=0,b=!0,c=this.opts.simultaneousUploads;return k(this.files,function(d){k(d.chunks,function(d){return"uploading"===d.status()&&(a++,a>=c)?(b=!1,!1):void 0})}),b&&a},upload:function(){var a=this._shouldUploadNext();if(a!==!1){this.fire("uploadStart");for(var b=!1,c=1;c<=this.opts.simultaneousUploads-a;c++)b=this.uploadNextChunk(!0)||b;b||i(function(){this.fire("complete")},this)}},resume:function(){k(this.files,function(a){a.resume()})},pause:function(){k(this.files,function(a){a.pause()})},cancel:function(){for(var a=this.files.length-1;a>=0;a--)this.files[a].cancel()},progress:function(){var a=0,b=0;return k(this.files,function(c){a+=c.progress()*c.size,b+=c.size}),b>0?a/b:0},addFile:function(a,b){this.addFiles([a],b)},addFiles:function(a,b){var c=[];k(a,function(a){if((!l||l&&a.size>0)&&(a.size%4096!==0||"."!==a.name&&"."!==a.fileName)&&!this.getFromUniqueIdentifier(this.generateUniqueIdentifier(a))){var d=new e(this,a);this.fire("fileAdded",d,b)&&c.push(d)}},this),this.fire("filesAdded",c,b)&&k(c,function(a){this.opts.singleFile&&this.files.length>0&&this.removeFile(this.files[0]),this.files.push(a)},this),this.fire("filesSubmitted",c,b)},removeFile:function(a){for(var b=this.files.length-1;b>=0;b--)this.files[b]===a&&(this.files.splice(b,1),a.abort())},getFromUniqueIdentifier:function(a){var b=!1;return k(this.files,function(c){c.uniqueIdentifier===a&&(b=c)}),b},getSize:function(){var a=0;return k(this.files,function(b){a+=b.size}),a},sizeUploaded:function(){var a=0;return k(this.files,function(b){a+=b.sizeUploaded()}),a},timeRemaining:function(){var a=0,b=0;return k(this.files,function(c){c.paused||c.error||(a+=c.size-c.sizeUploaded(),b+=c.averageSpeed)}),a&&!b?Number.POSITIVE_INFINITY:a||b?Math.floor(a/b):0}},e.prototype={measureSpeed:function(){var a=Date.now()-this._lastProgressCallback;if(a){var b=this.flowObj.opts.speedSmoothingFactor,c=this.sizeUploaded();this.currentSpeed=Math.max((c-this._prevUploadedSize)/a*1e3,0),this.averageSpeed=b*this.currentSpeed+(1-b)*this.averageSpeed,this._prevUploadedSize=c}},chunkEvent:function(a,b,c){switch(b){case"progress":if(Date.now()-this._lastProgressCallback<this.flowObj.opts.progressCallbacksInterval)break;this.measureSpeed(),this.flowObj.fire("fileProgress",this,a),this.flowObj.fire("progress"),this._lastProgressCallback=Date.now();break;case"error":this.error=!0,this.abort(!0),this.flowObj.fire("fileError",this,c,a),this.flowObj.fire("error",c,this,a);break;case"success":if(this.error)return;this.measureSpeed(),this.flowObj.fire("fileProgress",this,a),this.flowObj.fire("progress"),this._lastProgressCallback=Date.now(),this.isComplete()&&(this.currentSpeed=0,this.averageSpeed=0,this.flowObj.fire("fileSuccess",this,c,a));break;case"retry":this.flowObj.fire("fileRetry",this,a)}},pause:function(){this.paused=!0,this.abort()},resume:function(){this.paused=!1,this.flowObj.upload()},abort:function(a){this.currentSpeed=0,this.averageSpeed=0;var b=this.chunks;a&&(this.chunks=[]),k(b,function(a){"uploading"===a.status()&&(a.abort(),this.flowObj.uploadNextChunk())},this)},cancel:function(){this.flowObj.removeFile(this)},retry:function(){this.bootstrap(),this.flowObj.upload()},bootstrap:function(){this.abort(!0),this.error=!1,this._prevProgress=0;for(var a=this.flowObj.opts.forceChunkSize?Math.ceil:Math.floor,b=Math.max(a(this.file.size/this.flowObj.opts.chunkSize),1),c=0;b>c;c++)this.chunks.push(new f(this.flowObj,this,c))},progress:function(){if(this.error)return 1;if(1===this.chunks.length)return this._prevProgress=Math.max(this._prevProgress,this.chunks[0].progress()),this._prevProgress;var a=0;k(this.chunks,function(b){a+=b.progress()*(b.endByte-b.startByte)});var b=a/this.size;return this._prevProgress=Math.max(this._prevProgress,b>.9999?1:b),this._prevProgress},isUploading:function(){var a=!1;return k(this.chunks,function(b){return"uploading"===b.status()?(a=!0,!1):void 0}),a},isComplete:function(){var a=!1;return k(this.chunks,function(b){var c=b.status();return"pending"===c||"uploading"===c||1===b.preprocessState?(a=!0,!1):void 0}),!a},sizeUploaded:function(){var a=0;return k(this.chunks,function(b){a+=b.sizeUploaded()}),a},timeRemaining:function(){if(this.paused||this.error)return 0;var a=this.size-this.sizeUploaded();return a&&!this.averageSpeed?Number.POSITIVE_INFINITY:a||this.averageSpeed?Math.floor(a/this.averageSpeed):0},getType:function(){return this.file.type&&this.file.type.split("/")[1]},getExtension:function(){return this.name.substr((~-this.name.lastIndexOf(".")>>>0)+2).toLowerCase()}},f.prototype={getParams:function(){return{flowChunkNumber:this.offset+1,flowChunkSize:this.flowObj.opts.chunkSize,flowCurrentChunkSize:this.endByte-this.startByte,flowTotalSize:this.fileObjSize,flowIdentifier:this.fileObj.uniqueIdentifier,flowFilename:this.fileObj.name,flowRelativePath:this.fileObj.relativePath,flowTotalChunks:this.fileObj.chunks.length}},getTarget:function(a,b){return a+=a.indexOf("?")<0?"?":"&",a+b.join("&")},test:function(){this.xhr=new XMLHttpRequest,this.xhr.addEventListener("load",this.testHandler,!1),this.xhr.addEventListener("error",this.testHandler,!1);var a=h(this.flowObj.opts.testMethod,this.fileObj,this),b=this.prepareXhrRequest(a,!0);this.xhr.send(b)},preprocessFinished:function(){this.preprocessState=2,this.send()},send:function(){var a=this.flowObj.opts.preprocess;if("function"==typeof a)switch(this.preprocessState){case 0:return this.preprocessState=1,void a(this);case 1:return}if(this.flowObj.opts.testChunks&&!this.tested)return void this.test();this.loaded=0,this.total=0,this.pendingRetry=!1;var b=this.fileObj.file.slice?"slice":this.fileObj.file.mozSlice?"mozSlice":this.fileObj.file.webkitSlice?"webkitSlice":"slice",c=this.fileObj.file[b](this.startByte,this.endByte,this.fileObj.file.type);this.xhr=new XMLHttpRequest,this.xhr.upload.addEventListener("progress",this.progressHandler,!1),this.xhr.addEventListener("load",this.doneHandler,!1),this.xhr.addEventListener("error",this.doneHandler,!1);var d=h(this.flowObj.opts.uploadMethod,this.fileObj,this),e=this.prepareXhrRequest(d,!1,this.flowObj.opts.method,c);this.xhr.send(e)},abort:function(){var a=this.xhr;this.xhr=null,a&&a.abort()},status:function(a){return this.pendingRetry||1===this.preprocessState?"uploading":this.xhr?this.xhr.readyState<4?"uploading":this.flowObj.opts.successStatuses.indexOf(this.xhr.status)>-1?"success":this.flowObj.opts.permanentErrors.indexOf(this.xhr.status)>-1||!a&&this.retries>=this.flowObj.opts.maxChunkRetries?"error":(this.abort(),"pending"):"pending"},message:function(){return this.xhr?this.xhr.responseText:""},progress:function(){if(this.pendingRetry)return 0;var a=this.status();return"success"===a||"error"===a?1:"pending"===a?0:this.total>0?this.loaded/this.total:0},sizeUploaded:function(){var a=this.endByte-this.startByte;return"success"!==this.status()&&(a=this.progress()*a),a},prepareXhrRequest:function(a,b,c,d){var e=h(this.flowObj.opts.query,this.fileObj,this,b);e=j(this.getParams(),e);var f=h(this.flowObj.opts.target,this.fileObj,this,b),g=null;if("GET"===a||"octet"===c){var i=[];k(e,function(a,b){i.push([encodeURIComponent(b),encodeURIComponent(a)].join("="))}),f=this.getTarget(f,i),g=d||null}else g=new FormData,k(e,function(a,b){g.append(b,a)}),g.append(this.flowObj.opts.fileParameterName,d,this.fileObj.file.name);return this.xhr.open(a,f,!0),this.xhr.withCredentials=this.flowObj.opts.withCredentials,k(h(this.flowObj.opts.headers,this.fileObj,this,b),function(a,b){this.xhr.setRequestHeader(b,a)},this),g}},d.evalOpts=h,d.extend=j,d.each=k,d.FlowFile=e,d.FlowChunk=f,d.version="2.9.0","object"==typeof module&&module&&"object"==typeof module.exports?module.exports=d:(a.Flow=d,"function"==typeof define&&define.amd&&define("flow",[],function(){return d}))}(window,document);
\ No newline at end of file
diff --git js/lib/uploader/fusty-flow-factory.js js/lib/uploader/fusty-flow-factory.js
new file mode 100644
index 0000000..3d09bb0
--- /dev/null
+++ js/lib/uploader/fusty-flow-factory.js
@@ -0,0 +1,14 @@
+(function (Flow, FustyFlow, window) {
+  'use strict';
+
+  var fustyFlowFactory = function (opts) {
+    var flow = new Flow(opts);
+    if (flow.support) {
+      return flow;
+    }
+    return new FustyFlow(opts);
+  }
+
+  window.fustyFlowFactory = fustyFlowFactory;
+
+})(window.Flow, window.FustyFlow, window);
diff --git js/lib/uploader/fusty-flow.js js/lib/uploader/fusty-flow.js
new file mode 100644
index 0000000..4519a81
--- /dev/null
+++ js/lib/uploader/fusty-flow.js
@@ -0,0 +1,428 @@
+(function (Flow, window, document, undefined) {
+  'use strict';
+
+  var extend = Flow.extend;
+  var each = Flow.each;
+
+  function addEvent(element, type, handler) {
+    if (element.addEventListener) {
+      element.addEventListener(type, handler, false);
+    } else if (element.attachEvent) {
+      element.attachEvent("on" + type, handler);
+    } else {
+      element["on" + type] = handler;
+    }
+  }
+
+  function removeEvent(element, type, handler) {
+    if (element.removeEventListener) {
+      element.removeEventListener(type, handler, false);
+    } else if (element.detachEvent) {
+      element.detachEvent("on" + type, handler);
+    } else {
+      element["on" + type] = null;
+    }
+  }
+
+  function removeElement(element) {
+    element.parentNode.removeChild(element);
+  }
+
+  function isFunction(functionToCheck) {
+    var getType = {};
+    return functionToCheck && getType.toString.call(functionToCheck) === '[object Function]';
+  }
+
+  /**
+   * Not resumable file upload library, for IE7-IE9 browsers
+   * @name FustyFlow
+   * @param [opts]
+   * @param {bool} [opts.singleFile]
+   * @param {string} [opts.fileParameterName]
+   * @param {Object|Function} [opts.query]
+   * @param {Object} [opts.headers]
+   * @param {string} [opts.target]
+   * @param {Function} [opts.generateUniqueIdentifier]
+   * @param {bool} [opts.matchJSON]
+   * @constructor
+   */
+  function FustyFlow(opts) {
+    // Shortcut of "r instanceof Flow"
+    this.support = false;
+
+    this.files = [];
+    this.events = [];
+    this.defaults = {
+      simultaneousUploads: 3,
+      fileParameterName: 'file',
+      query: {},
+      target: '/',
+      generateUniqueIdentifier: null,
+      matchJSON: false
+    };
+
+    var $ = this;
+
+    this.inputChangeEvent = function (event) {
+      var input = event.target || event.srcElement;
+      removeEvent(input, 'change', $.inputChangeEvent);
+      var newClone = input.cloneNode(false);
+      // change current input with new one
+      input.parentNode.replaceChild(newClone, input);
+      // old input will be attached to hidden form
+      $.addFile(input, event);
+      // reset new input
+      newClone.value = '';
+      addEvent(newClone, 'change', $.inputChangeEvent);
+    };
+
+    this.opts = Flow.extend({}, this.defaults, opts || {});
+  }
+
+  FustyFlow.prototype = {
+    on: Flow.prototype.on,
+    off: Flow.prototype.off,
+    fire: Flow.prototype.fire,
+    cancel: Flow.prototype.cancel,
+    assignBrowse: function (domNodes) {
+      if (typeof domNodes.length == 'undefined') {
+        domNodes = [domNodes];
+      }
+      each(domNodes, function (domNode) {
+        var input;
+        if (domNode.tagName === 'INPUT' && domNode.type === 'file') {
+          input = domNode;
+        } else {
+          input = document.createElement('input');
+          input.setAttribute('type', 'file');
+
+          extend(domNode.style, {
+            display: 'inline-block',
+            position: 'relative',
+            overflow: 'hidden',
+            verticalAlign: 'top'
+          });
+
+          extend(input.style, {
+            position: 'absolute',
+            top: 0,
+            right: 0,
+            fontFamily: 'Arial',
+            // 4 persons reported this, the max values that worked for them were 243, 236, 236, 118
+            fontSize: '118px',
+            margin: 0,
+            padding: 0,
+            opacity: 0,
+            filter: 'alpha(opacity=0)',
+            cursor: 'pointer'
+          });
+
+          domNode.appendChild(input);
+        }
+        // When new files are added, simply append them to the overall list
+        addEvent(input, 'change', this.inputChangeEvent);
+      }, this);
+    },
+    assignDrop: function () {
+      // not supported
+    },
+    unAssignDrop: function () {
+      // not supported
+    },
+    isUploading: function () {
+      var uploading = false;
+      each(this.files, function (file) {
+        if (file.isUploading()) {
+          uploading = true;
+          return false;
+        }
+      });
+      return uploading;
+    },
+    upload: function () {
+      // Kick off the queue
+      var files = 0;
+      each(this.files, function (file) {
+        if (file.progress() == 1 || file.isPaused()) {
+          return;
+        }
+        if (file.isUploading()) {
+          files++;
+          return;
+        }
+        if (files++ >= this.opts.simultaneousUploads) {
+          return false;
+        }
+        if (files == 1) {
+          this.fire('uploadStart');
+        }
+        file.send();
+      }, this);
+      if (!files) {
+        this.fire('complete');
+      }
+    },
+    pause: function () {
+      each(this.files, function (file) {
+        file.pause();
+      });
+    },
+    resume: function () {
+      each(this.files, function (file) {
+        file.resume();
+      });
+    },
+    progress: function () {
+      var totalDone = 0;
+      var totalFiles = 0;
+      each(this.files, function (file) {
+        totalDone += file.progress();
+        totalFiles++;
+      });
+      return totalFiles > 0 ? totalDone / totalFiles : 0;
+    },
+    addFiles: function (elementsList, event) {
+      var files = [];
+      each(elementsList, function (element) {
+        // is domElement ?
+        if (element.nodeType === 1 && element.value) {
+          var f = new FustyFlowFile(this, element);
+          if (this.fire('fileAdded', f, event)) {
+            files.push(f);
+          }
+        }
+      }, this);
+      if (this.fire('filesAdded', files, event)) {
+        each(files, function (file) {
+          if (this.opts.singleFile && this.files.length > 0) {
+            this.removeFile(this.files[0]);
+          }
+          this.files.push(file);
+        }, this);
+      }
+      this.fire('filesSubmitted', files, event);
+    },
+    addFile: function (file, event) {
+      this.addFiles([file], event);
+    },
+    generateUniqueIdentifier: function (element) {
+      var custom = this.opts.generateUniqueIdentifier;
+      if (typeof custom === 'function') {
+        return custom(element);
+      }
+      return 'xxxxxxxx-xxxx-yxxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function (c) {
+        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
+        return v.toString(16);
+      });
+    },
+    getFromUniqueIdentifier: function (uniqueIdentifier) {
+      var ret = false;
+      each(this.files, function (f) {
+        if (f.uniqueIdentifier == uniqueIdentifier) ret = f;
+      });
+      return ret;
+    },
+    removeFile: function (file) {
+      for (var i = this.files.length - 1; i >= 0; i--) {
+        if (this.files[i] === file) {
+          this.files.splice(i, 1);
+        }
+      }
+    },
+    getSize: function () {
+      // undefined
+    },
+    timeRemaining: function () {
+      // undefined
+    },
+    sizeUploaded: function () {
+      // undefined
+    }
+  };
+
+  function FustyFlowFile(flowObj, element) {
+    this.flowObj = flowObj;
+    this.element = element;
+    this.name = element.value && element.value.replace(/.*(\/|\\)/, "");
+    this.relativePath = this.name;
+    this.uniqueIdentifier = flowObj.generateUniqueIdentifier(element);
+    this.iFrame = null;
+
+    this.finished = false;
+    this.error = false;
+    this.paused = false;
+
+    var $ = this;
+    this.iFrameLoaded = function (event) {
+      // when we remove iframe from dom
+      // the request stops, but in IE load
+      // event fires
+      if (!$.iFrame || !$.iFrame.parentNode) {
+        return;
+      }
+      $.finished = true;
+      try {
+        // fixing Opera 10.53
+        if ($.iFrame.contentDocument &&
+          $.iFrame.contentDocument.body &&
+          $.iFrame.contentDocument.body.innerHTML == "false") {
+          // In Opera event is fired second time
+          // when body.innerHTML changed from false
+          // to server response approx. after 1 sec
+          // when we upload file with iframe
+          return;
+        }
+      } catch (error) {
+        //IE may throw an "access is denied" error when attempting to access contentDocument
+        $.error = true;
+        $.abort();
+        $.flowObj.fire('fileError', $, error);
+        return;
+      }
+      // iframe.contentWindow.document - for IE<7
+      var doc = $.iFrame.contentDocument || $.iFrame.contentWindow.document;
+      var innerHtml = doc.body.innerHTML;
+      if ($.flowObj.opts.matchJSON) {
+        innerHtml = /(\{.*\})/.exec(innerHtml)[0];
+      }
+
+      $.abort();
+      $.flowObj.fire('fileSuccess', $, innerHtml);
+      $.flowObj.upload();
+    };
+    this.bootstrap();
+  }
+
+  FustyFlowFile.prototype = {
+    getExtension: Flow.FlowFile.prototype.getExtension,
+    getType: function () {
+      // undefined
+    },
+    send: function () {
+      if (this.finished) {
+        return;
+      }
+      var o = this.flowObj.opts;
+      var form = this.createForm();
+      var params = o.query;
+      if (isFunction(params)) {
+        params = params(this);
+      }
+      params[o.fileParameterName] = this.element;
+      params['flowFilename'] = this.name;
+      params['flowRelativePath'] = this.relativePath;
+      params['flowIdentifier'] = this.uniqueIdentifier;
+
+      this.addFormParams(form, params);
+      addEvent(this.iFrame, 'load', this.iFrameLoaded);
+      form.submit();
+      removeElement(form);
+    },
+    abort: function (noupload) {
+      if (this.iFrame) {
+        this.iFrame.setAttribute('src', 'java' + String.fromCharCode(115) + 'cript:false;');
+        removeElement(this.iFrame);
+        this.iFrame = null;
+        !noupload && this.flowObj.upload();
+      }
+    },
+    cancel: function () {
+      this.flowObj.removeFile(this);
+      this.abort();
+    },
+    retry: function () {
+      this.bootstrap();
+      this.flowObj.upload();
+    },
+    bootstrap: function () {
+      this.abort(true);
+      this.finished = false;
+      this.error = false;
+    },
+    timeRemaining: function () {
+      // undefined
+    },
+    sizeUploaded: function () {
+      // undefined
+    },
+    resume: function () {
+      this.paused = false;
+      this.flowObj.upload();
+    },
+    pause: function () {
+      this.paused = true;
+      this.abort();
+    },
+    isUploading: function () {
+      return this.iFrame !== null;
+    },
+    isPaused: function () {
+      return this.paused;
+    },
+    isComplete: function () {
+      return this.progress() === 1;
+    },
+    progress: function () {
+      if (this.error) {
+        return 1;
+      }
+      return this.finished ? 1 : 0;
+    },
+
+    createIframe: function () {
+      var iFrame = (/MSIE (6|7|8)/).test(navigator.userAgent) ?
+        document.createElement('<iframe name="' + this.uniqueIdentifier + '_iframe' + '">') :
+        document.createElement('iframe');
+
+      iFrame.setAttribute('id', this.uniqueIdentifier + '_iframe_id');
+      iFrame.setAttribute('name', this.uniqueIdentifier + '_iframe');
+      iFrame.style.display = 'none';
+      document.body.appendChild(iFrame);
+      return iFrame;
+    },
+    createForm: function() {
+      var target = this.flowObj.opts.target;
+      if (typeof target === "function") {
+        target = target.apply(null);
+      }
+
+      var form = document.createElement('form');
+      form.encoding = "multipart/form-data";
+      form.method = "POST";
+      form.setAttribute('action', target);
+      if (!this.iFrame) {
+        this.iFrame = this.createIframe();
+      }
+      form.setAttribute('target', this.iFrame.name);
+      form.style.display = 'none';
+      document.body.appendChild(form);
+      return form;
+    },
+    addFormParams: function(form, params) {
+      var input;
+      each(params, function (value, key) {
+        if (value && value.nodeType === 1) {
+          input = value;
+        } else {
+          input = document.createElement('input');
+          input.setAttribute('value', value);
+        }
+        input.setAttribute('name', key);
+        form.appendChild(input);
+      });
+    }
+  };
+
+  FustyFlow.FustyFlowFile = FustyFlowFile;
+
+  if (typeof module !== 'undefined') {
+    module.exports = FustyFlow;
+  } else if (typeof define === "function" && define.amd) {
+    // AMD/requirejs: Define the module
+    define(function(){
+      return FustyFlow;
+    });
+  } else {
+    window.FustyFlow = FustyFlow;
+  }
+})(window.Flow, window, document);
diff --git js/mage/adminhtml/product.js js/mage/adminhtml/product.js
index bc738e5..60633c9 100644
--- js/mage/adminhtml/product.js
+++ js/mage/adminhtml/product.js
@@ -34,18 +34,18 @@ Product.Gallery.prototype = {
     idIncrement :1,
     containerId :'',
     container :null,
-    uploader :null,
     imageTypes : {},
-    initialize : function(containerId, uploader, imageTypes) {
+    initialize : function(containerId, imageTypes) {
         this.containerId = containerId, this.container = $(this.containerId);
-        this.uploader = uploader;
         this.imageTypes = imageTypes;
-        if (this.uploader) {
-            this.uploader.onFilesComplete = this.handleUploadComplete
-                    .bind(this);
-        }
-        // this.uploader.onFileProgress = this.handleUploadProgress.bind(this);
-        // this.uploader.onFileError = this.handleUploadError.bind(this);
+
+        document.on('uploader:fileSuccess', function(event) {
+            var memo = event.memo;
+            if(memo && this._checkCurrentContainer(memo.containerId)) {
+                this.handleUploadComplete([{response: memo.response}]);
+            }
+        }.bind(this));
+
         this.images = this.getElement('save').value.evalJSON();
         this.imagesValues = this.getElement('save_image').value.evalJSON();
         this.template = new Template('<tr id="__id__" class="preview">' + this
@@ -56,6 +56,9 @@ Product.Gallery.prototype = {
         varienGlobalEvents.attachEventHandler('moveTab', this.onImageTabMove
                 .bind(this));
     },
+    _checkCurrentContainer: function(child) {
+        return $(this.containerId).down('#' + child);
+    },
     onImageTabMove : function(event) {
         var imagesTab = false;
         this.container.ancestors().each( function(parentItem) {
@@ -113,7 +116,6 @@ Product.Gallery.prototype = {
             newImage.disabled = 0;
             newImage.removed = 0;
             this.images.push(newImage);
-            this.uploader.removeFile(item.id);
         }.bind(this));
         this.container.setHasChanges();
         this.updateImages();
diff --git js/mage/adminhtml/uploader/instance.js js/mage/adminhtml/uploader/instance.js
new file mode 100644
index 0000000..483b2af
--- /dev/null
+++ js/mage/adminhtml/uploader/instance.js
@@ -0,0 +1,508 @@
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    design
+ * @package     default_default
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+(function(flowFactory, window, document) {
+'use strict';
+    window.Uploader = Class.create({
+
+        /**
+         * @type {Boolean} Are we in debug mode?
+         */
+        debug: false,
+
+        /**
+         * @constant
+         * @type {String} templatePattern
+         */
+        templatePattern: /(^|.|\r|\n)({{(\w+)}})/,
+
+        /**
+         * @type {JSON} Array of elements ids to instantiate DOM collection
+         */
+        elementsIds: [],
+
+        /**
+         * @type {Array.<HTMLElement>} List of elements ids across all uploader functionality
+         */
+        elements: [],
+
+        /**
+         * @type {(FustyFlow|Flow)} Uploader object instance
+         */
+        uploader: {},
+
+        /**
+         * @type {JSON} General Uploader config
+         */
+        uploaderConfig: {},
+
+        /**
+         * @type {JSON} browseConfig General Uploader config
+         */
+        browseConfig: {},
+
+        /**
+         * @type {JSON} Misc settings to manipulate Uploader
+         */
+        miscConfig: {},
+
+        /**
+         * @type {Array.<String>} Sizes in plural
+         */
+        sizesPlural: ['bytes', 'kB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'],
+
+        /**
+         * @type {Number} Precision of calculation during convetion to human readable size format
+         */
+        sizePrecisionDefault: 3,
+
+        /**
+         * @type {Number} Unit type conversion kib or kb, etc
+         */
+        sizeUnitType: 1024,
+
+        /**
+         * @type {String} Default delete button selector
+         */
+        deleteButtonSelector: '.delete',
+
+        /**
+         * @type {Number} Timeout of completion handler
+         */
+        onCompleteTimeout: 1000,
+
+        /**
+         * @type {(null|Array.<FlowFile>)} Files array stored for success event
+         */
+        files: null,
+
+
+        /**
+         * @name Uploader
+         *
+         * @param {JSON} config
+         *
+         * @constructor
+         */
+        initialize: function(config) {
+            this.elementsIds = config.elementIds;
+            this.elements = this.getElements(this.elementsIds);
+
+            this.uploaderConfig = config.uploaderConfig;
+            this.browseConfig = config.browseConfig;
+            this.miscConfig =  config.miscConfig;
+
+            this.uploader = flowFactory(this.uploaderConfig);
+
+            this.attachEvents();
+
+            /**
+             * Bridging functions to retain functionality of existing modules
+             */
+            this.formatSize = this._getPluralSize.bind(this);
+            this.upload = this.onUploadClick.bind(this);
+            this.onContainerHideBefore = this.onTabChange.bind(this);
+        },
+
+        /**
+         * Array of strings containing elements ids
+         *
+         * @param {JSON.<string, Array.<string>>} ids as JSON map,
+         *      {<type> => ['id1', 'id2'...], <type2>...}
+         * @returns {Array.<HTMLElement>} An array of DOM elements
+         */
+        getElements: function (ids) {
+            /** @type {Hash} idsHash */
+            var idsHash = $H(ids);
+
+            idsHash.each(function (id) {
+                var result = this.getElementsByIds(id.value);
+
+                idsHash.set(id.key, result);
+            }.bind(this));
+
+            return idsHash.toObject();
+        },
+
+        /**
+         * Get HTMLElement from hash values
+         *
+         * @param {(Array|String)}ids
+         * @returns {(Array.<HTMLElement>|HTMLElement)}
+         */
+        getElementsByIds: function (ids) {
+            var result = [];
+            if(ids && Object.isArray(ids)) {
+                ids.each(function(fromId) {
+                    var DOMElement = $(fromId);
+
+                    if (DOMElement) {
+                        // Add it only if it's valid HTMLElement, otherwise skip.
+                        result.push(DOMElement);
+                    }
+                });
+            } else {
+                result = $(ids)
+            }
+
+            return result;
+        },
+
+        /**
+         * Attach all types of events
+         */
+        attachEvents: function() {
+            this.assignBrowse();
+
+            this.uploader.on('filesSubmitted', this.onFilesSubmitted.bind(this));
+
+            this.uploader.on('uploadStart', this.onUploadStart.bind(this));
+
+            this.uploader.on('fileSuccess', this.onFileSuccess.bind(this));
+            this.uploader.on('complete', this.onSuccess.bind(this));
+
+            if(this.elements.container && !this.elements.delete) {
+                this.elements.container.on('click', this.deleteButtonSelector, this.onDeleteClick.bind(this));
+            } else {
+                if(this.elements.delete) {
+                    this.elements.delete.on('click', Event.fire.bind(this, document, 'upload:simulateDelete', {
+                        containerId: this.elementsIds.container
+                    }));
+                }
+            }
+            if(this.elements.upload) {
+                this.elements.upload.invoke('on', 'click', this.onUploadClick.bind(this));
+            }
+            if(this.debug) {
+                this.uploader.on('catchAll', this.onCatchAll.bind(this));
+            }
+        },
+
+        onTabChange: function (successFunc) {
+            if(this.uploader.files.length && !Object.isArray(this.files)) {
+                if(confirm(
+                        this._translate('There are files that were selected but not uploaded yet. After switching to another tab your selections will be lost. Do you wish to continue ?')
+                   )
+                ) {
+                    if(Object.isFunction(successFunc)) {
+                        successFunc();
+                    } else {
+                        this._handleDelete(this.uploader.files);
+                        document.fire('uploader:fileError', {
+                            containerId: this.elementsIds.container
+                        });
+                    }
+                } else {
+                    return 'cannotchange';
+                }
+            }
+        },
+
+        /**
+         * Assign browse buttons to appropriate targets
+         */
+        assignBrowse: function() {
+            if (this.elements.browse && this.elements.browse.length) {
+                this.uploader.assignBrowse(
+                    this.elements.browse,
+                    this.browseConfig.isDirectory || false,
+                    this.browseConfig.singleFile || false,
+                    this.browseConfig.attributes || {}
+                );
+            }
+        },
+
+        /**
+         * @event
+         * @param {Array.<FlowFile>} files
+         */
+        onFilesSubmitted: function (files) {
+            files.filter(function (file) {
+                if(this._checkFileSize(file)) {
+                    alert(
+                        this._translate('Maximum allowed file size for upload is') +
+                        " " + this.miscConfig.maxSizePlural + "\n" +
+                        this._translate('Please check your server PHP settings.')
+                    );
+                    file.cancel();
+                    return false;
+                }
+                return true;
+            }.bind(this)).each(function (file) {
+                this._handleUpdateFile(file);
+            }.bind(this));
+        },
+
+        _handleUpdateFile: function (file) {
+            var replaceBrowseWithRemove = this.miscConfig.replaceBrowseWithRemove;
+            if(replaceBrowseWithRemove) {
+                document.fire('uploader:simulateNewUpload', { containerId: this.elementsIds.container });
+            }
+            this.elements.container
+                [replaceBrowseWithRemove ? 'update':'insert'](this._renderFromTemplate(
+                    this.elements.templateFile,
+                    {
+                        name: file.name,
+                        size: file.size ? '(' + this._getPluralSize(file.size) + ')' : '',
+                        id: file.uniqueIdentifier
+                    }
+                )
+            );
+        },
+
+        /**
+         * Upload button is being pressed
+         *
+         * @event
+         */
+        onUploadStart: function () {
+            var files = this.uploader.files;
+
+            files.each(function (file) {
+                var id = file.uniqueIdentifier;
+
+                this._getFileContainerById(id)
+                    .removeClassName('new')
+                    .removeClassName('error')
+                    .addClassName('progress');
+                this._getProgressTextById(id).update(this._translate('Uploading...'));
+
+                var deleteButton = this._getDeleteButtonById(id);
+                if(deleteButton) {
+                    this._getDeleteButtonById(id).hide();
+                }
+            }.bind(this));
+
+            this.files = this.uploader.files;
+        },
+
+        /**
+         * Get file-line container by id
+         *
+         * @param {String} id
+         * @returns {HTMLElement}
+         * @private
+         */
+        _getFileContainerById: function (id) {
+            return $(id + '-container');
+        },
+
+        /**
+         * Get text update container
+         *
+         * @param id
+         * @returns {*}
+         * @private
+         */
+        _getProgressTextById: function (id) {
+            return this._getFileContainerById(id).down('.progress-text');
+        },
+
+        _getDeleteButtonById: function(id) {
+            return this._getFileContainerById(id).down('.delete');
+        },
+
+        /**
+         * Handle delete button click
+         *
+         * @event
+         * @param {Event} e
+         */
+        onDeleteClick: function (e) {
+            var element = Event.findElement(e);
+            var id = element.id;
+            if(!id) {
+                id = element.up(this.deleteButtonSelector).id;
+            }
+            this._handleDelete([this.uploader.getFromUniqueIdentifier(id)]);
+        },
+
+        /**
+         * Complete handler of uploading process
+         *
+         * @event
+         */
+        onSuccess: function () {
+            document.fire('uploader:success', { files: this.files });
+            this.files = null;
+        },
+
+        /**
+         * Successfully uploaded file, notify about that other components, handle deletion from queue
+         *
+         * @param {FlowFile} file
+         * @param {JSON} response
+         */
+        onFileSuccess: function (file, response) {
+            response = response.evalJSON();
+            var id = file.uniqueIdentifier;
+            var error = response.error;
+            this._getFileContainerById(id)
+                .removeClassName('progress')
+                .addClassName(error ? 'error': 'complete')
+            ;
+            this._getProgressTextById(id).update(this._translate(
+                error ? this._XSSFilter(error) :'Complete'
+            ));
+
+            setTimeout(function() {
+                if(!error) {
+                    document.fire('uploader:fileSuccess', {
+                        response: Object.toJSON(response),
+                        containerId: this.elementsIds.container
+                    });
+                } else {
+                    document.fire('uploader:fileError', {
+                        containerId: this.elementsIds.container
+                    });
+                }
+                this._handleDelete([file]);
+            }.bind(this) , !error ? this.onCompleteTimeout: this.onCompleteTimeout * 3);
+        },
+
+        /**
+         * Upload button click event
+         *
+         * @event
+         */
+        onUploadClick: function () {
+            try {
+                this.uploader.upload();
+            } catch(e) {
+                if(console) {
+                    console.error(e);
+                }
+            }
+        },
+
+        /**
+         * Event for debugging purposes
+         *
+         * @event
+         */
+        onCatchAll: function () {
+            if(console.group && console.groupEnd && console.trace) {
+                var args = [].splice.call(arguments, 1);
+                console.group();
+                    console.info(arguments[0]);
+                    console.log("Uploader Instance:", this);
+                    console.log("Event Arguments:", args);
+                    console.trace();
+                console.groupEnd();
+            } else {
+                console.log(this, arguments);
+            }
+        },
+
+        /**
+         * Handle deletition of files
+         * @param {Array.<FlowFile>} files
+         * @private
+         */
+        _handleDelete: function (files) {
+            files.each(function (file) {
+                file.cancel();
+                var container = $(file.uniqueIdentifier + '-container');
+                if(container) {
+                    container.remove();
+                }
+            }.bind(this));
+        },
+
+        /**
+         * Check whenever file size exceeded permitted amount
+         *
+         * @param {FlowFile} file
+         * @returns {boolean}
+         * @private
+         */
+        _checkFileSize: function (file) {
+            return file.size > this.miscConfig.maxSizeInBytes;
+        },
+
+        /**
+         * Make a translation of string
+         *
+         * @param {String} text
+         * @returns {String}
+         * @private
+         */
+        _translate: function (text) {
+            try {
+                return Translator.translate(text);
+            }
+            catch(e){
+                return text;
+            }
+        },
+
+        /**
+         * Render from given template and given variables to assign
+         *
+         * @param {HTMLElement} template
+         * @param {JSON} vars
+         * @returns {String}
+         * @private
+         */
+        _renderFromTemplate: function (template, vars) {
+            var t = new Template(this._XSSFilter(template.innerHTML), this.templatePattern);
+            return t.evaluate(vars);
+        },
+
+        /**
+         * Format size with precision
+         *
+         * @param {Number} sizeInBytes
+         * @param {Number} [precision]
+         * @returns {String}
+         * @private
+         */
+        _getPluralSize: function (sizeInBytes, precision) {
+                if(sizeInBytes == 0) {
+                    return 0 + this.sizesPlural[0];
+                }
+                var dm = (precision || this.sizePrecisionDefault) + 1;
+                var i = Math.floor(Math.log(sizeInBytes) / Math.log(this.sizeUnitType));
+
+                return (sizeInBytes / Math.pow(this.sizeUnitType, i)).toPrecision(dm) + ' ' + this.sizesPlural[i];
+        },
+
+        /**
+         * Purify template string to prevent XSS attacks
+         *
+         * @param {String} str
+         * @returns {String}
+         * @private
+         */
+        _XSSFilter: function (str) {
+            return str
+                .stripScripts()
+                // Remove inline event handlers like onclick, onload, etc
+                .replace(/(on[a-z]+=["][^"]+["])(?=[^>]*>)/img, '')
+                .replace(/(on[a-z]+=['][^']+['])(?=[^>]*>)/img, '')
+            ;
+        }
+    });
+})(fustyFlowFactory, window, document);
diff --git lib/Unserialize/Parser.php lib/Unserialize/Parser.php
index 6a79e17..3d63b2a 100644
--- lib/Unserialize/Parser.php
+++ lib/Unserialize/Parser.php
@@ -34,6 +34,7 @@ class Unserialize_Parser
     const TYPE_DOUBLE = 'd';
     const TYPE_ARRAY = 'a';
     const TYPE_BOOL = 'b';
+    const TYPE_NULL = 'N';
 
     const SYMBOL_QUOTE = '"';
     const SYMBOL_SEMICOLON = ';';
diff --git lib/Unserialize/Reader/Arr.php lib/Unserialize/Reader/Arr.php
index 6201c2c..c48e468 100644
--- lib/Unserialize/Reader/Arr.php
+++ lib/Unserialize/Reader/Arr.php
@@ -101,7 +101,10 @@ class Unserialize_Reader_Arr
         if ($this->_status == self::READING_VALUE) {
             $value = $this->_reader->read($char, $prevChar);
             if (!is_null($value)) {
-                $this->_result[$this->_reader->key] = $value;
+                $this->_result[$this->_reader->key] =
+                    ($value == Unserialize_Reader_Null::NULL_VALUE && $prevChar == Unserialize_Parser::TYPE_NULL)
+                        ? null
+                        : $value;
                 if (count($this->_result) < $this->_length) {
                     $this->_reader = new Unserialize_Reader_ArrKey();
                     $this->_status = self::READING_KEY;
diff --git lib/Unserialize/Reader/ArrValue.php lib/Unserialize/Reader/ArrValue.php
index 8f76420..e61af2c 100644
--- lib/Unserialize/Reader/ArrValue.php
+++ lib/Unserialize/Reader/ArrValue.php
@@ -84,6 +84,10 @@ class Unserialize_Reader_ArrValue
                     $this->_reader = new Unserialize_Reader_Dbl();
                     $this->_status = self::READING_VALUE;
                     break;
+                case Unserialize_Parser::TYPE_NULL:
+                    $this->_reader = new Unserialize_Reader_Null();
+                    $this->_status = self::READING_VALUE;
+                    break;
                 default:
                     throw new Exception('Unsupported data type ' . $char);
             }
diff --git lib/Unserialize/Reader/Null.php lib/Unserialize/Reader/Null.php
new file mode 100644
index 0000000..f382b65
--- /dev/null
+++ lib/Unserialize/Reader/Null.php
@@ -0,0 +1,64 @@
+<?php
+/**
+ * Magento Enterprise Edition
+ *
+ * NOTICE OF LICENSE
+ *
+ * This source file is subject to the Magento Enterprise Edition End User License Agreement
+ * that is bundled with this package in the file LICENSE_EE.txt.
+ * It is also available through the world-wide-web at this URL:
+ * http://www.magento.com/license/enterprise-edition
+ * If you did not receive a copy of the license and are unable to
+ * obtain it through the world-wide-web, please send an email
+ * to license@magento.com so we can send you a copy immediately.
+ *
+ * DISCLAIMER
+ *
+ * Do not edit or add to this file if you wish to upgrade Magento to newer
+ * versions in the future. If you wish to customize Magento for your
+ * needs please refer to http://www.magento.com for more information.
+ *
+ * @category    Unserialize
+ * @package     Unserialize_Reader_Null
+ * @copyright Copyright (c) 2006-2016 X.commerce, Inc. and affiliates (http://www.magento.com)
+ * @license http://www.magento.com/license/enterprise-edition
+ */
+
+/**
+ * Class Unserialize_Reader_Null
+ */
+class Unserialize_Reader_Null
+{
+    /**
+     * @var int
+     */
+    protected $_status;
+
+    /**
+     * @var string
+     */
+    protected $_value;
+
+    const NULL_VALUE = 'null';
+
+    const READING_VALUE = 1;
+
+    /**
+     * @param string $char
+     * @param string $prevChar
+     * @return string|null
+     */
+    public function read($char, $prevChar)
+    {
+        if ($prevChar == Unserialize_Parser::SYMBOL_SEMICOLON) {
+            $this->_value = self::NULL_VALUE;
+            $this->_status = self::READING_VALUE;
+            return null;
+        }
+
+        if ($this->_status == self::READING_VALUE && $char == Unserialize_Parser::SYMBOL_SEMICOLON) {
+            return $this->_value;
+        }
+        return null;
+    }
+}
diff --git skin/adminhtml/default/default/boxes.css skin/adminhtml/default/default/boxes.css
index 84f6e1c..b35ef5e 100644
--- skin/adminhtml/default/default/boxes.css
+++ skin/adminhtml/default/default/boxes.css
@@ -78,7 +78,7 @@
     z-index:501;
     }
 #loading-mask {
-    background:background:url(../images/blank.gif) repeat;
+    background:url(images/blank.gif) repeat;
     position:absolute;
     color:#d85909;
     font-size:1.1em;
@@ -1396,8 +1396,6 @@ ul.super-product-attributes { padding-left:15px; }
 .uploader .file-row-info .file-info-name  { font-weight:bold; }
 .uploader .file-row .progress-text { float:right; font-weight:bold; }
 .uploader .file-row .delete-button { float:right; }
-.uploader .buttons { float:left; }
-.uploader .flex { float:right; }
 .uploader .progress { border:1px solid #f0e6b7; background-color:#feffcc; }
 .uploader .error { border:1px solid #aa1717; background-color:#ffe6de; }
 .uploader .error .progress-text { padding-right:10px; }
diff --git skin/adminhtml/default/default/media/flex.swf skin/adminhtml/default/default/media/flex.swf
deleted file mode 100644
index a8ecaa0..0000000
--- skin/adminhtml/default/default/media/flex.swf
+++ /dev/null
@@ -1,70 +0,0 @@
-CWS	-~  x�̽XK�8���i�޻��E��.X@PH	AB�Ih"`î�{��X����E,�b��������~���{�6;sΜ3sʜ�M��\��A�� �.	R�C�H�@���wTP�in�P$��5k�L���䔓����(��:�xyy99�:��:��<���� �ZX���xR�$-S�&�buN�8K�cm�����d��%�,S�N<!/�'�I�\] ��7_,���|9���4.c�� ���9�l�_ȑ
-8u5�hdi2!��?E��3
-�2�:��P�H���L!O���y*t�('%�!sR�%K8�<�.X"K��E�\Y�\.���,Y�PJ�!TH�s�H�ɂx�4Qf��������!s��"��e�Z
-�ϓHx)C;�3q��O�B.|*)b.�D�D9YP�,��N����	'�,�Am�D2�
-�+E����j(�t稕�+�7�P�21O�e�妉��0�f�Q�da�^�RW}D�`&��T
-]��?8-:�K,R�0X'���4��?�2�s��
-���àB7���a"h�G�b�!�L%	/�'�7����)����ޝ~���)I��,{��w�d
-�z��K����������#���g��4Y'3H���$yF=H�~���N%%Ie�L��ap�S#�D��II�I0��A)2��#ĝV��x)����aC��0��Ȕ2�̸f��'��8�)��eh�h7����҄�4��;��hҬd)�!N�G���m�	c�)q�S@Qp�]1@�GD������
-�d|�i@d �XG'�D��'�Nc9���*�
-������
-�aL7F�6J	'���IdOF��ps���C����TX�8sD�e������x0�Ȣ��i�
-��z��`x6U5�s҄�S��C9���z �^�J��EɸE��0�,��6E�Nej�ꪓm]]]7�;�?ѡ��������O�����N��% 6�.�ndD(STT��54��I:�=�z�DUc`B3�ր���f�4�͜�7�$�Q��(��DJRBI�(사Fc �@QM(���j��J�CQ}��!J6BQc5AQS5CQsX��%
-�P�
-�Q�EmQ�E�Q���(ꈢN(������~(ꁢ�(ꅢ�(s ����
-�B�?���@�d ���HCA
-�Q0#P��XT/�K@��P�AA2j���E� 
-D���(�	
-�(���Y�r6���*��|L(���P�9�P�y ՟a JX��}1�/�K�m���
-Ĭ(y5���k-�����i��+���� !!;��/ lM��i�	��&�2�;=�(������E P�@	�uoN��wj7���"� ���FJe��� �NW�Uu��k �&�	��$C 4��d��P}�( D� L#�(�a� ������� ZV Q��5@4l B����F�==����4P�%��!z}�}G@�C^Np�}�D�ҙ�X��.��J!��n�9�ؗB2'�)���QPs
-уB6G�:��S�d�F6���A���-
-	P�9��� 8� ���fŔ#	!Z' �c�#�P(*�^휠d��B&��9T;'��|�.���%��\�Z}=,��D7K��-��%Y�Q�D:��v�DnY"u�fl�Y���@'��T`�hg�.�K��#�JT��$ZX,�Lz���D���U�$�$�	郰��>�D[ye(��&�F�"l?6���:���P,KD��%��J�aEj,�:i�*Ah	�7�Vt�p�����=Q/A�2%\��zl
-?�m��ҋFl"l(JD�a��iq���޴�K��m��`F�}��n�j�����qI���P��%'�X��%��L��H&�$�%�	�7B�A
- �Zu�� �*�%��@�� ��j���$:�0!� ���e�}�a� �FMH8P�^� ��B:��P�K�viw˙L�3 X"��!�v�AV]
-�OԲh%�u@"Ԁj	��B&A?B#�yTE}5ԧm��:>"[lD��Sq��"�D�`e�����P,&��dW�J��ܨ��T��*�T;�8�B����3�����{L)B�"h�B�0c�	�:]"s�H$aX��NÀj
-pPawP� ��&��fM��,N�,��vU�T���� &Y�yp��D(�+-�S6G	�Ʉ�dD� z�FG��`k���Ă��R�js 6�갩6`Ή�/�M5ؼ�Oؙ��#�		Я�L�����}��}1��F���b�-��Y�!y-��D���ܸ^��Ğ� �tq�(b
-�L&! hI"��a$I�"	F���D��ut�u�[�/Px,����ǰ�;*�|!^I�ׄ�䐐��@.��0>ܓ�un�F�	P#j�W(A���{�?�!�.+���m������	�ݪ�����Am�G`�A��a�Q���N���%a������	��H-�G�.�j)L�i�̆�XSm��Ѭ��Ʋ�3[�̖:�e��,gv�3�	�b���%`��:� V;â. &���U��G$3�3@�b1pI5x8�S�.e[c��s؄��`�/��Q�0ıփ:l�&�!�k�0�0U�p�a;��<(�)���9�ɤ���6�
-��&�Vׄ���'��V;�ؘ�X#aG#0���n_��C�^b��%uH� �3pc �ڈ �$�����
-��p#��qتg �ܩXs8\�
-4P>6\K48B�EǦ�Z�i�!��$��Xb�"��3ܿ�s��y�v�Z|�9�CR�P��}�*�s��у�7U�Ў�*٩�2�!�/�_��i�"قPꮰ�^�E��T7�X�m��+�����M��02�+& 	�&ې/O��F���'lH9��	n���	��cx'�����6�����^�/
-0K?*����)��8	26�����%<N8;�@m�m�\޴ە����4
-�K����ߨ��RV�)���UΤ�'��ΛVft
-A�Ağ/�B<�v��(��ի�7����O����{������%$�w�`��F�q����v߄�u�S��w?�|���d�@{Sr����M[�l�%�����"�������2��"�,�ݼR��$�|��!�vާ-�	������z����z=��y���R�s&C����'��l��S������O˼%�����Q;G���@��!dUDɽ[��}Шa��~M�\$<{�����<�aQfw��G��'�ߺ��j�b����W^�ܣ�?c�������'��಑��W��N��~ɻ�_��j鮐{+\��~�=w����!?	�J���y7���7��7b�M6�U��e�����&�{?���V�8�X�����.�_�~x{�)m����ϛ�O�f�|�7:Rw�FM�{��cו{#-�v����b����s���
-^������]����������k����e�֏��m_X����mи�qhX�3c3�{�o��P{�}ֶ/-޽&�u7�8�5vJɫKo��;�ap���zJ���CZ�;�i#�ͯ�3��=�0㵒yi�Z�9�_|�s9����
-VM�9g۰���*K7���$ٿ�{ak�i�W�'ْ}n.c�����HU}2�Q�f�c�N�Ů	k��>\�{��֤_J�U7�h�0�0�)b
-��U��2bJ%{]��qs�VP�̼�Ǐ����o-���s�KW\h;�r/�_e��"��miSS�}CQ񗤦v""�Z�֩яɘ����N�n9R�|�Ƈ~�Nl�N��d��RljGo$���mC��ku-=���aB��LҏqQ?=fü��'u�&,,(6�_���0�?.�������x!}��8�[;q���+Gd�>h�ii��N�}��Rg���U�s.�Y��]��Ф�6UǱO���<�酉���_%?/�X�o7��;f~Y��H��C�Z:�M�,v�O��X�����k�̀���������ï�ÎH�/
-Ύ\�x����%��K/�.^p���S�$݄��{���8�-�p���f���S��d^֮z��(}<��ڵn��$�N��/G�~�)�����.��f��Ieo֣ʖk7M}���s�ۣ��^��=G����9R�_;���譞�l�?�;lX���WgU����ҋ.m+�8��"�[x���OE�+����{�3)cI�4}�|��OK�W}�'����F��G��ؘ��N$����V���N��<�e�h�K���f��_W���Ν��>�##;��´�L�_���l������b������d"yuG�^�>��ƆS$}��sϥ�>����Μ��+��rV/�c����o%V=3k�4��㳍�g�N��f��*��V��Y�����#�V~�w�7O�O�ڷg���	G���Ⱥ �<����C�.li�>!?�ؘ��o�6�;yD�[�>������F]��A:�dY��V�շ@[�}>�N���9�:�J�Lu��`$��*_��{鱖�o>K,x�,޴kX/�z>�Akc�y#Ú�S���s���O��e`?w�|E�ńFQ]è��wߗD�X���`U�ɯ���o��^8W I9��fc�y�z�"�_v.z������/1��4{���_~�zr<�3)�Ǭ���о�k-��E�o��n8.>l[V" �Y�~0��E��#�����ͷX�p�N�>��������=��s�5i�IQ����'�^]<r����!�C��m�����W�/o-,��U?6ha|�%���&�w+6���%ڸ��;��C����l?��V������-{�X��\}߶}���:�B�б�W�P��c����E����S�4	&�W}��;�;�rc��#��I�h��#o�@I�̢�����K���ǻ�����4_�OCg���������6�S�f��o���>�fE�������[�GmO7k��q{��˓�FO#J|�V��t���}Xf=�?��k��M���?y��m�Ӯ;��\�R��:账�̧��s��_.ptr���r��'��4�K.L̘�m���sV~�F��@�X������'b]tT��g鮭F�f��9=]���4hh�:��k�*E��B�Vi�{PP�p�ɷ��|�}9��2�Úx���{˪�3�������J�~�5��:���u�/3�\��8`��[�*�GK��}��TY��O>\�Rj�5�/��c+�>��4���2�B�r����s��ƜW���|���W�~Vٚ8e�����M�k�{\�������5!�A�������̥MO�ԍ�ʝ3�+��Mۏ��ML6�Eo���}�꧟�3����������f��ؒ�e2y{�4��n̂���3�s�o�+B�6x����"��g�&
-�9�����+�������k2E�Ϗi����_�k��O�2��i�F���;0vu���c��}>N�y����E�.pA����><g��<��{}S�������o�#ƣ�QC�l�<v�ˤ6��c�������x��׫�%�:w�q�_WF�.�඲r`���/o�i�|��iɗ'�A-Y'�)��xIs���e.q��=2~\>XqOM�{W�d3+����{F4I��!u�.ߞ���pԴs����8;���j�w����������+��Wlv��U�����%_�*n��vQ�]RQ��m�_7:-˗������ש{e<}�mfӏ��/"N~ٲwt��mF���s�׭����Z�?n� ]�m���[5coa������Q����Hnt/��^��1��Hʅ<^�[��߃ל���y���6G�;Hf1uL��_�氇d��(�5�3�H�uLF
-8��8��o����ߟ�'ڑ��as�S�qyiVn���
-V�៣�^�6K���8��������;$��&�ُ�N���+���y#3w���~��{t�X�Wc/��PKU��sy��j�i��A�����T�tt~��%u��K�>@�:�&rU����,���m����r�c� Q�ح+E:�u�'�s��w���|t�Q�d��0_&lWӚ_<@wo����)~��^O}�;�0���K�O���Gl�L��/��8�3���}�=�زŸ$g����鿨��	�ͤ3Τ2��GFDX�������Ny_�$QQ�(��x�k��Wh��늧�<n\*�zm�m����z��i3#~Ա~͙������9w��Ϙ_[�
-��6����J�}M��M[�b�Dz��y\X��/~�ߔ�3�%n�k�����޳(�O�/9ݲ΃s|��y�Y'^^�_t����l��,Q\#mُ)y1E��$q���z-���^'k����_,I�|�i��}$I7_�;���̈�7������:_��Z���y��[Ѻ��ڗ��.;[��F��s��%���^��f��r4�-��(����|���+$�g<�]�vU��ᏩWm�������}��y�KSx�kS�9d��˵��/�:5�ۀm�W��?O����H2���~N�ۆj� ���:��k�ߝ}X4wBz�RƜC�o��ս>���R�� e�kK�O��*�jH�%.�IZ�<����i%�T��}Ez���G��]Qe��n�廡���pl٥^�~<�{mōk��>�g�����z7�����m�G��t���ݥI3��V�h�F��ꡝ{��/��1���ν�Ts퐸����_��H1��ۿ=ٿ�� *��^};v܀Ц�'g��K%�9�9��?Zʯ:�D�kޯʓ�����Lnx��X5���G��+l����,ԫ4��v�þ�I�YT0qoB��j��C��g��ܟq��V��Pm���0~w'��XP�=�QgБ���<m���}ض���r���ʳ}rtޜ�8�+@�~�\hqE�;zp�c�5�c��]��z~.�5�,�Ϳ���^��s�	���^qk�������嗕/W��ڛ��_e���93"N�^{$-���4�O�䟛�j՘�~�=���=�s�^8|V9g�����I~Dr1i������g��=���X9���*�JݵN���
-Z
-�����0���ɱ;^Äz���m�5��$#��"7���m���%����V]}8rf���i���\>�q�uA΢��;������T�Kɜ�y�;�rYb�C	Y����#�e�1�CW�Z�#�zчx��ր��A����5��1콋���g|mn�2ܒK��0���0�8O?��j���X�c��e�#F�XC�zZ�P����3��ܞ�
-֚����iA�j
-�R^R�8G�=��l����2M�KA��!�2�*��~�N���'NՐ+��S�6�F��o&��mooG7��J.����r}-:k�.���GH_�67_^B~�t���HYwr�q�_������7f>�;l\�:��?h�z◯�+�i�K?��-j���[�Z?��%�>�<�3�Ȍo���W��&��Ƈ~��?�=�鮟�?�*���7P��;��r��h_�b9��P������C@z����u���,	�'U�R���s��S���Z�ݡY�<��Hh�3�t��<��C�N��<h�qFW%,������
-Ӱü�a%��ͤt���p���~?���E��EB�<.�T��Q�]����)Y"���b�+�Bq2GH���p�C8�:r0N��
-9\R9<z�$-�'e�%HC��<����U��S��@;�)/*â��j��xC��a'��������@�b1
-+c@�}��"'eJę<�,
-f��}�y��uܫeP���p�&Ix�b	T_,I��B�')z$�|Rj?��ӥ��{?7OW����ț��ϳ��{_Ͼ�,zQũb�W/7g//O��yY�I.n^n}=]]=�P��Ix��#`Y����b+�u"; :�'�{�4���0QJ���4i�������I-��]3����R��&
-���Qo��Z+�F��q&G(��c�4�������CL���0��Y������)r��1-�R�����0
-V$0��C�#,ׂVJ��;\�T�+F���f�k���,�ct3�F`t��˗
-�L���,l�
-�2��-��ך��ް�|؝��%�O������h���ިcadc��#�d*	Ē�q�A]�f�(weN@�Lm�r�d�?�,K��4��_�)�HUpub+��N�Cn#�%��,��Mq")]&�V�ˌH�8N)상�@N�7adrRR����29\��Q���-�{ldt�f�T�řd.�J7R�J�/��J8)X̒��o�
-Q�Z�����*]4x[u��đO8�h���H���z�(�\,�E���R�sгT��SSᶫC��]/E�R����f�9�{���1��\MX��nH����L�l��ܳ�������'�~
-�O)��ʦ�'_�Ktc9Tl�x�6�c��4MԋC&�~�@��G�s�Rl��,26li/���4�#����0��0\�e/1�W:����J��w.��6�w)p$�`O��#xڜ�2�I�x����R�2�ry�h'3�'�4�G K���2�3i�8ML
-��@�ˇ�R4�4(4]��%@���i�2�P�1
-�Q�	�4E�f�����@Q�s�(۠�v(�GU�D�(�%;�4��7T�/
-�Q�(�D�J�FI�Q���}�P �	� !��@�(5��EM#P�H�tj�2�(̑(3eơ�Q(3e�F�	(3e&�L6��gI\`�RP�G�S�r�ӱ\)4J�H�b!3 ����| *��>��@�@-����|��x��W;�&h�$�Tɀl@A�,�������T�y�O�y�4/ f!uZ���ZB�yC�"�/���PZ JBi�(-E-�P�e�J0���aӵ���@HC�6��Vxm����I���hj��d[�-%J78�'I�,
-,�[|�@�D�8�X���e
-�oP�~�� �����""4�3��d*:!���v`���//\��B%��
-��F|(4$;d�p��Dd�I����}	H�_D���� "�@@H�ဈ�� �����P5"u B����H8BF!h0����TEH�HBF��r�j$�ajD}�1Sp�A�GE�Uq�B ~H ��L���Ԉ�j�ar�p5J�5R����Fb�id�1f�E L@(@���K�z�HD#`N$S`IB����(v������LB�.����<A_���$�����?� !JA���(�/��I��П��
-oR�Dv��tp(�=�&r�;	8�$rg�z5�:8C���?(}16�.�{u?�r*��ě,�
-�^�q����=�K���f K�9W��?��Y���f��*������Q g�B�N�%���^
-_�'�nu��&ξ�O���
-���������Nª�[���q��
-��^�f��@6�B� U���Y�����]{��.>�|���ԋ^��.��B������-��OZ�5`Rpݫ�7��@���~�����w�G���/��B'((��9A;BIЌ�D���Xr��ʔ�c'����k�[*F� 1(�;<��-�	��L'P�-.��q���j� *[g���Ahɴd�q1v
-�4S��z�	�'"�M�Bő��u	�	�5��`ݍ�HBH0�-k�4��@x�&��!�m��)v\R��W�E�j�L��v\�� �$�&�Xm�f]�D�@"����P�oԄ�;~�!@ �{j=�a�	$��İF`������`?`��e�&؆8c,�:FH��bI�I$r̫�LjBL@�X����5��I@끵�)x������$�2t\T��~�B�JR@IT�L&����S�,�W�hV1!D�y͈�U�1�K&��7�4$
-p��HɤZ���v�_]"�D��uQ�֫�K����:.�4B�:�t�:�|Xs=Efp��)XfpLn}Lny�r�_�	d�6���h�[5��LGV3Ol���Q"��%A�1�R�w|=j�����i,Y`	!f��t�,s�3��.m�Y�D{v���X��e��@�[X�"�����T�����}0�
-?�F���}C��Hu����r�3;ϙ=Ι�����b)Yۭ`s��\��=r��)2�'��{>V�/�� ��T������ˡ�W���v��8 ��3'�����������%�f�y@��F�~!��X�����B̛���I�o!pɊC �+'7Qq@���ڕ�4E�{.�2mYJ���<4�<�₢��w�Z�5�����`ԸU�7������%���-�W��wf��!h2I�ν��s�9��{����:OB*5t�D��F�%U�x1Cd8y[`|x.��He���Dk[`�bo҄�KE�D8Z���	�J�F�K���ȝL%��������,�j$���hr�W��������\����Vk���Y��N�g�I�0O�Zqeb^\�bl{du d�ryj�*��:� k �|���A�=�����! ���25H��c7�SV��fNY��W�/9[;��m��*[���˷����=�J�R�hk��m�E��fQ݄E�0g�䚶CA%���݈K,*�$��ES�A�wS��.�
-��D�Z8s�z*�,��ܶC�m�z��� �fg�p�«A%;1�\
-�^KN C{#
\ No newline at end of file
diff --git skin/adminhtml/default/default/media/uploader.swf skin/adminhtml/default/default/media/uploader.swf
deleted file mode 100644
index e38a5a5..0000000
--- skin/adminhtml/default/default/media/uploader.swf
+++ /dev/null
@@ -1,875 +0,0 @@
-CWSu� xڤ|	`E�wWWw���$��� �Cu�]�]�@B�IP��0IfȬ�cg&{"�� xq��
-�Pak{Kc��TB����k&'e�[f�g�N��M���I��A0:���;���ڱ���Q���j1��8��d����J��=�Ge�z��7��� в��>b�(���-�[���hk�1�k�]�lAձx]͜x"�<�
-*��|GQ(c8l���J� �r�j��U���{�q����.6�5�7{5��=�����o>����y�@b��{��������$�����d+���\���^8E�����ྎ���� ��<e�����S�����S��w۸?�ʯ�~J�E�G�:e�t�8�>�"ƴ�FC�mfk��#�kD{"��K#
-bMjml��ʃ4�s�5�����٩�2�B����F�e�?MI��6c|2'�O0���Bg��a�Me�X��&oEU*`Z����)��Ck��i�XY�r[,d-�xaM[0vni�b8e�	Ʋ�C���X����PC;�z��*/ʈ���
-'�(����
-t�5.lk�4�mP&���h���D�h�!��	R*�t��c��F[gY��+Z*C�Px���V�ĩQ���YN�)�lD�ROZ������ fE� �ӐZ0�JT4�Y;��-��V��*��ˈ$��\(���f��Z\h���OI�5���PV��$�Fն7��#'�	V�4�fg��Cy��S|
-�1�p]
-�$n5�����l8wF�,7f�5�~�p$
-)�����2�Jv�jO�4f͈�����[�ˊ�m'�&u�Q�YM�D-���M����'ػJ�n�X���8�3�W-Z%
-:��u�OE2"1
-*�,j,��f!m-3�|l������$]�s�5�!��K��Kd�\���vΣS��9����h{(��h[�HQ�b��͹(�@��M,yc���z5;Қ�/}L{�@z��>X=�D͹�2CT2ݭa��%�$�}���d����CE&]�r�a�1XMG�PKC(����'�[:��H�lDA�]����4N^��O*��b�t$���+)N`��e���'7z��{%���������
-����c�{�B�Ͷ�؜y����Xz�SMK�t,�F�ړ�.4�h�����G��r��7� ؽ�I�k�D�>:��L��)��5���K?���*4yљUQ��t���䔥s��.CR�����`����U����S��_�b�iݤY���N��Ҕ��ҜT�����^��Ty�趜��VZX����<�]�q��H���n��o崖�mҰ_�������J��xh*ߤ�ʺ3*Jk��UT�_V�T25��][6��nRI�8��<�
-v�,:Gj2W�}%��1M�9O�9Q9u�3�N��ui��KM[�u3쨫>�6��2�)���uy��d�=Z�0zgxi�њ"���i�'��Ƀqd�P�\��q�ϥ���4�
-�g���I�|N���Π���]�N��Cy,8]tIA&πHVT�P8���9��:��&?m�O�^��d�K3Gئ��ƞ�w��iJ����l�T*F$N6gnYzZa���������ѥm4%�'P�j�K'cs�Ƅ'���rǒ,? �*�ſ���z}�a?���/���`�[rMS
-w`Z�ѽ�0��q��8Ӻ��p��HZ~3�d�ַ�H�l����h��w8�uXRj�Q��$u��B.�c�%��Pv�q��+�b��IU�LU�r<R�Ǧ�Z�3e�Lwc,8�jl��ʭ���x�t�*�!��޵�%�8�9�K�]��,��'e�f<��H�G�!���&���sbvJ;�t��K!�4����Y�h��3�e�x�7Y����|�s��e�5U��ߌ8��F�ʮ(�XVW;���f|���,���-�>�d��6�D���9��8��-$-B�r~�Ċ����TM*;c|YuYv���5�-g5�QPZ5eJ�*���;�،�y���ԔՕV�Q�J��M�_�L7�������>,�.`��29��g_�%��[iY61�,W&;�)�&S��`k(Z��O���yJ}��CI���u�|�"�t�s��h�J����7�ޞ��ֶ���ݖ�Ǣ�Q����m!�d	����PRo��'������p�Ywg"�^��jj[�u�	ŦTWЮ#�E2^��j��������[��M�8�k5�F1&���(
-H�s�xHI���5���'za�5'���K$�~�+)-��\]6�������%iW|^J1�j��e�e��C�Ie��U�.�/�N���uR�I�#2���nrIuYem]�Ĳ���)�򒱵U�g�U��6���v`r��
-�>ٹH�O
-�e9�R�{�ff���Hm$G�_qt����S�˫�N��9��d\Y5}!QNoQ���L���WR%��|n�M�3�1Sjk����oL	V�eg�`�Ԕ���ϩ�9�iB���K*ǕՕU����P��赙5�%յ�-�~�����r�luYf�|
-+&�֥	unKȺfJ��C�S]�O�R�l���!�eYH}�#�ZҀ%]RzfA�R����3����9I���ش]���d�a��n+$�š�d3��d��B�ՔM,k-9�8nFC��?k�5��g�[i��䒏'���9�R��R�S&cZ�W�����0����ʚ��IN��G��V�
-�B�z+�|V�=�NK�>g����k�&��m�IUo�[J[�}_�K1֥{�"�TQ�Wg��Id����L�H+fbUunF�Nf2���[��Fw]$^��k�����+�j9���Yp�`;w�g��Lj���A_��2ڏ�.x'FZ�g�4?Vy��I_~��H�]�?[8}�#+2�z��$[c&��e}®�LV�rZ����d�f�":09��x�����j�X� (��P���	�LfX��Y[5�nb��e��pl����X�q��,�R�)-�dW�7�Uk_���vJ���1��
-m��:�brIi݂�M���@���j+*K�؞� 5�� �;~��h����rO��������Q.G�\��.�]^û��rnZ���Qmݜ7�xv~o��q��s�4�GO;�Y����a����y���l�,m �r�UYUW3�db�wXn��$���榼VR�+cd��9�Oƍ�F4�2#�4��V*��TI�	ַR��0�"-Z[{�I�c�5ү����!�ż�ƽ�m��3���zm�$l��RY��Nә\�'�K���/��2��M�Lf�_��Hj3��������BK��xt�Owu�n(��I�c�[�7�Q(�����MܩC�����);��ˇ�]�[~[іh�� ��V����q%<7�v㱊�XVrz�;uA��q��%P��Y���
-s�E�wRMk���e#<t�)�|Ua6Ҍ����R
-Y�]Ef�+&Y72�?Gi �-J_��U��j����rՈ��z���,��R��C�.]����$�u����N����D�2Y#u-&�
-��I�Dˠ���X<iAxm���e��,�ĚY�.M����l�;�^~$i�u��*_ȋ�p�c]3W��6)�h���پx��tF�8iO�����Iǰ>�7���T�93�������dh�q9�����p���az�g7b��b�i��������G����e�Ëm�4��F����.[ׯ��7�`�npL��&�
-��kM��7,��?ʈJ��
-��x��Grt�Do��K*[����=U3?��Q.��}6WA�ma/�Ɉ����7����ɲٳF�}v陕%�*�N�62������4/"+&M���E��Xf�	S�nJu���NaG�#F�#F�ua���m�m:��6Cv/L���9A��&�,�L�ژ�Ӗv�H������w<]|7���D�ׇ��m�i���)n��G��H}�"[L_^Ƌ[c������D1$�i���ʺ8�|O��=���)�Sm^���_/U$���s�e�~�b���Y�dN�0��_~��WQ{��j�FC����byf*vn"18�eF�����^��X�1��ܟ���'Z����1��ql��]�Zc�g��q�V����]꧃���9LF��O����K�pP��M*V���W���t�����q����
-�+�y���ۗ
-BJ��b����]r�Y�c�����c��d'�&Q��洲��A=���%	V�F��괳���FZش�p{4j�<�;
-_*l}��5�"Q51[M�ɑk��ѰrhA��j�'��O�|��N�1�unKkùP��tl"s^�i7���S����F�ڂ��R�X�����L��E�t�Ay+`Z�Q�*p
-
-�
-/8�`p���N*����5��W{�
-�+��Y��u�Zx��+�K@\���{��(��Z�]-ܡ���j�侣��S?P?��Oj�A��<^8���箋��R#f�UD兏��'�u��o�S^�9/��|��%�R͵Ls��
-�h�7h�b�+z�2-0t�Oa�
-Vt�Qt�Qt�Q��(Zf-7
-/7\F�ה�Q/�\t�Z�S��]-�^����Eo���w��.��T����Q���qE���\����3������jj��~��3�:�/N�N���ײ�j��`�z'}fP3X�'T3 <�y�I숦H͑eGd.`�fGk5�t�Q(�eJ��V��y��9:6�u�p��5��ʙLOԌ��ŲO}R�f���NtM>���9"��d�w���?�Y�����?��U]��}Dd�X��.�T��Pu���L�{����+X�`ق���/�\��	�/����W��	~�`��1@��B(��=Hx��P�>J���aB.<�
-1B���{�p/�'�o���"�w��^d��?�E��B?E�?�D�ʄ�\��	�x��	�w��M�I�W)|U���W���
-��?]�������%�g��33O5��"0M��:�.A��h���E`�4�@D�*�@T�E�EZE�M�&1����3E��;K���sD��E�?D�?E�D�E�D�\&r��������E���%�B`�X\
-ԋ���\\\	,�˙�W13��}5�����k�ȿ�u��𯂻�	����� �c"�F������L�7����
-�
-�N2t2�Q�{x�'�kl�`�{�����g�n��U?oH��p�D~'
-�7"��}؃�^`���TcɊ���y�Z��v�`g6U�3;K��;U���U��W��U�5�u� ��&��6��.
-�l�`���>�d�A�W���Y����џ����O�O�π�Q����W
-��6�~��0y'a�N�䝴������`����䧀���y��S��v@'�t�{���>`?��"��2�
-�*��:p x������Ls	���\�i.�4���~���|�t���������/�(���q�q�����#��3�pi�S���	v�&�̓;��p�� �p/�{1�K�.���b�K�^
-�2��W��&*�W+41�j��Z�:�zM�4�Wk∵6(lf끛�߀26�3�M�������f�n�^`+p�
-xx�w�@�&*���`n�~MTaL����� � ���> >>>� ���~ ~~���w`ppp	�X\\,�+���k����Z`�� l6��w����{��t��]L~P�=lv ;�G�G�ǀǁ'�'����i���xx�
-8� �E�b`	p��O������V����E_�Z�:�z`�a�6��X� �3P����_�47b� �� �$��DS6�Y7#���w&����������C�pm��0��	<<
-<a�`�`��Q�O���4��x�%�q�J�4M��4̕��D|
-l���_ __������? ???� 
-^����[��p��25�<�@���\��*N]/�~>q�U�:R �槪��D�Ef��sHV?���i���j�����﫪�)��-dy[�˅f�)�����/����}a��9�,s>W�5h�N�����iƁO�πρ/�/���P����o����i&���D�|Q�Rͅ`��谹 ��%T���цy��bp/��D�rW�>XD.'r-���u.�4�1��+4�@���}��ߪE��P�*W�~�f����c�֣��\�gH�%�k����M�-��.1������]�f`p7pp����f�!�<��Y���42(]�Z-�&�Oj��,��EU5��hMq�n���ǣ���L�LJ�1��?/
-��BTV��e�Odd^�Ve؝
-��&*�]�굓�@���"R��:���lYT�Q�^���ڣ�,�$j�J��[L�f��Qy
-�W�R�_�M�츟<�/7y��M�C�>iiXv�C�Y6���c�YAM�ۭR��T�T� I��Xͮ7Ǚ]���]o�rӷ��$=g��Ș�T=V��@J>)M�]���8d4 7-���bD8d P�N8|������ɶ#��7b�c!�v���+�^��MeR��%���J��k�0ˇ1�J���?��Q�'s��t˨�ć��~nVj�5(Նld��j��>d=�zM��#�O(�1�Q\�k���w����l �``��!ɽj�ץ�.�=����&$��kRvjn��P�[��l���h����0���wڟ�6L9�Q�����+���rR=4��{ 5�y$�e �^g�ɣ���2Fd�I������AE�����1Xq���S��&��I�;�\��.�ʤ�ƌ��aB9^*��Y�����W�<���͑S�X-=�G����<y=�J�zu�Eԩ�Χ��1�~��,�AH=��(%sm@���J~��j����u�e���tࡍ�VFy�җ��Z�е���#��l����s���դZ93�`U���{�J������;,����Gg6����n���H�9�`�.�RtlZ����!6x�kKS��HK��4hT+����>ғ�$��V5xk	1w;l^��y�����%}����ݶR�:3c��i}��tT���C�:��h�<Y�/�Ф�(��w���P����+]=�������0��0":�M��\�'ͲRz�b)/ɀ�a����*2��X-�IVr��0e�����dg��*����Q��h�U�D��c��=f�$���1u�v�G�x�Ĕ��<�s���OaJ��L�-aJ
-�˔�R��)cJa9S��cJ�x���Ut^1������*�OR��I\X�*GT�ʑU\4YU��*C�Ueh5W��Q��kUe�U9�tU~��;UUF�ɔ�g1e��L9�/L9~SN8�)��c�o�3�� S~W�ii��ۉ��򇐪�1�*
-s���rJ�����+%U��ؿ�J�_�Rv����˕qQU�JE��Lh�ʩ-�2�UU&��JeW���*��ƕ�b�R�JM\Uj�\��P��\9�]U��s�̙�r�L��=KU�2�+�f��9��R7GU���J��R�w�4��)��dJ�_L	��)3��*Ms��#��uS�s�1�D���|>H�D�^ �v����&\�N���\��5Sf-�U��,"GYl���v_�Ȩ��r�\���q%���p�1e9#k�*F�V�J8W3��x��W�N~=#�\%�jFKb
-콛٫�ob��{�Vv �6����7A�`o�s'{�.��f�.�����}�{����A�������Ǡ��'���OA`��>�>}�}��}	�0�
-t�t'���-��;�������@�`?�>�~}���4��vt����������Wi��d@�����B���"�=�bн��}l!�~����E��%v)���2�W�堯�+@_cW��Ζ�`�@�`�A�dW���V���V��î�{�5�^���ˮ}�]����*�?`��������UI�o��c��v#�l=�g�&����/�F(k�v3B_�M�f_��[���#�����ʏ�VY�'���nSi߿�U��r���<P��<P9��BysU�4�)�U�f�v�-*�z�����^��
-��}��+��P�_%���/RP�r���L�8��ۥ�a��;d���/R��hrۦ������^ʕ�����+W��ÿ�+��'�_�>	z���
-�iЕ�3�W�r�.����u��_ʕU�s���u7�k���N�u�\�Q�=(WnR��ߠ>�Q�z3(W6�{��+����
-]���Mm淀n᷂��o���z/��Jy��wr�����p<�߇c���|�߅�|3�;A������\y��
-�3�\���C���m��)]ܸ}��ū����C�|;ru򇑾���'�|��NN��#�,�G%}L�ǥ(=a
-ӝ`uiw�խ�e�6�����=��u7X{���ڧ�c��k�v/X/h[�e���zQ����m�~�^�����˫ڃ��i�5�+oh���Ic�����y_�!�;�v�w��A�ӎG�W�ki;P���N�?���+�i���9(W��C_j�kOh�ʷ����iOb�'*?k�z�2Z�Oi�@�����͟�^��4E��'���Z�WX�$T�$_5����nd�ܢ���ܦ�N��<wh�K3t�]��óEc�k��ܣ�=(�AXS��v�b�Ճ�UTFU�Ľ�F��հ�`
-�U�p���ZtE@��XWL�b]qC��n�-:Ԟr��dA�J6t���x�ޭz������n���~�0�􀘫=�\�i�s��]��k����=�]���Yh����Gu�E�c��w1����>��x�aO�7��t����͞�!u�b6���?��a�\�)�s[��gŽK�Co>���1�����P�|�n0o6�@]�މ$;��.�|��?M(�=hAA.ߋ��}�a��'SU�4ǻ�����^������_��mM�PS�I��AK��K��G�e��'mx�ڟ�`e��r�tc�
-�KƎ��������&Uc�����*�)��Uv���ϩl7�w���Ab������ʖ�����Ӕ���݆`΅�-��[��b��E���d?]�٥���l���^��Z�`E�������� .֔>wr��B���ܾq{Y)�������\�)���wl���X���+5�%��[�v���y��M�iʑ�j�:�����*����V��ƎՔ�hl��%r��
-�4�:��<���OU�r���Ŝ��Ǜ���sf���u�S������s���'����yF���v�.m2���.
-|��?ԃ���Q�{���� ��a��)zy@G	C�2
-���b��GQ�LUXx�>ի>Օ��3�\�_x��U�;�_�s�y�Z�
-S1����U���b���C�)���W:=�N�Z��ZW|CPﴫ٠�	W3�t
-�Ęk�R�Խ*��?��4��
-�(���R.7pv��0
-
-���f�.��I�?*QS�O!�+U`���^�Z�	�O���h��,A{:�-����mwNj������uZ�r��.����v��T6�*EM�d�C����]!g������k����O�U�n�J�7�����*��6ѮP�]��:�>L �fMNE0�n�I�w2��(���}�4�ݝҞ�$��ku��2�����2��;�n��mF{ȝL���1l/�ر�����.������.iP�[��su��2�f�&�o��ޑ�-iu�+9wKN��ǒ�{�-�*���˓ԽLnO�<�����`���u�%�).
-r��S;��f�����@ڱ�c�.�,��w�������G3���l&U%�v�n*=����(��14��|���m�cD��YРa p�m0,�j��v獲����j��[��'~��"�7p� �0�{�
-������2��n`��ݴ&�26aS��Bh�҆���b[�/�5���)Fqx����?�����12);,��l�)�m�B��@`$�n�Ӄzn�s����N�:�D�N��`t���%E�_��<U���ݴ���1�]����5W1���W4�Q��
-�at�Չu!����ڴ<�OްAOuAE�(��z�:cB?f���{�_��̾�_����Y~�!���u�2�ѡ�R�Å4���H�Z��9�o�fK�L�uȁ/��qz���Hj��ַ��/�;�MH�ɸ��Y�R�W
-y�z��4��D�o�BʳvHQ/��e�T˝�݋���m/�?-��t�x'M�Z��
-�7��g� ɼ������;�[���`,_���b��ΚJ�sܞ���R^�,y	o4��w1DtV�l(���aU���.�.(��[
�P���}�%�ǡ��%���-��ͬI�W;w�8�[��R�����cB?N'4=����f�mH�\^iZ��m�.���w�"����ˆ)K���0�u.�1�	#�Kݳ�g���K��/�A���A�?FR�<jt�/�vܪO�2���P)�����%��7�:��ɩj����D�Ev)�T���d�_�PD�\��4ɠ}힙�NU���{e���=ݖ�).a�b�0������7Ӧx��M�eSHK��_��2�R>�R�4-�Zd�z����O��Zw�F����;H���j�D-d4��|��s�Aަ;z�l��b��kZ1���6��U�iH��bXi�<���X�-�;�|n�:��4��]�t��5����n�J�w }�}\������:��H2��yR�>Ψ@����9)U'҆��T�>�묇��%rb^�3Ԟ��MG�;��:9�jNZ���a�=�4i�J[�LP�����dG�8:���6�+��C;&l6��-#k�� ;�۱��2%�󒽧'{o��}���'��~�'�%�~�'��~�'�5�~�'��d����챶�7�K
-6�0�˞i��r���i&}��;e?��,γ��q��w-�����j�O�֪�� ���Lk���_�cI���BN]�(��"�Y$
-�}9��:���KݿA�$�r��}Kݮ_G[g�v�w��]3��:�.
-�C�Z�tZ�P���lޛ�3d���u<��M�S:J�'�k7H߾�Ҵ�s�}��k�(��#Zw��6�r#����erC|CJ_�D;O���*l���E���0�p����4^�������Um�)�F���.�t�;�G�����MX��j��|��
-���e�(z�9�ٔ?�E�V����9<��~Q�k��;GW�J��)��s:�{��f�-
-K_U�䚂��C�af�\޽�S0q.��$0	�Y�j>
-������HHps�0�.l�S	�v�\hBD�
-��Y�]A�ӡ'T��zL0�a�+#�KA5����Y�a��W���5��l*J�Luc}���^�j3���8Ւn����lO�lVt��f�ٶ(�;L�f����(�듊 HTc��<�}���)(� ���l�7�\�Ap�� �=sklLu����_ހ��/	�
-���Jn�-�{��]�d��̂�D_2�3�}7�d'���2��	��oh#]s��j2
-i���!W�Fe��
-�*,K%���x
-�2�� ����h�Ӈo�sjٹ�I�Ҳ ��z�ʐ��:��sG��G����fCE��N���~C�z�Yg�J!d�(�*�K.�����\��0�EK��/Q��?��Ä�r{��A�(4�� v��h�^p��h$��Y�tF��Э��5��?�΋����較�z��7 �ьS<�����⌽��7�M�'����������"���Y�k=o G��1R)�;=� ��M0W�9�(a`�I���;
-�H���
-�)ز�,�?�Wq���;���f&<��e=��q�<8�帻�]� *�?��ه��p�g��,���dщ)�r�=�NW85���(9]bl���'*���\঺�\��ft�־sG'��	T��+��
-
-�V%AT��+�VT���1]Y^�~.��W�"�
-�,i�R�i)|��=��G�%J�n@�`y�T����~?��/��~��+�sU�n
-�KVvf�P]"��k4�И�Nc�*�=��I9��ߦ�ޮ��42�!k2�_�uދ=����� L����a���Wk���ݫ��7���ih�p�~SH�O�L��c�r�d�|���4F�ρ��=+s�y�d4�ځ_�1;�+>no��k2�>a��
-�e]Q/H����j�A���0cQ�]�.�^�F�-J����V�ji+�r9}��v��m!�j��h^,&� �	n��X5�V]K�@�q�sf�U�w�\��
-���$�m��(�'����| P��-[
-�Lk| ��v��:X�r�?��T�������+�m���N�[�-*�Ѧ����Z^�u��܅>l��1Jk��<a���2�Y&��r�)�6;OQ�6EM5��LmGW�KF���BBń���g�཮�@\�,�
-k*WtKf�j�45<�n$�"����T
-����f(W�}pA�W�����y~6?�}���x��).w��:
-�����������D���3�V�\L����FHG�C��Bw]ϫr�9u᫲x@�����>GI�H�q�nAvsr�6rC$�I/%X����rd�.}��p�qB"oB���@Ӌ��T0��U�xտ��}��ڰ��Ÿ����~.
-�c�x���g��Gz>�ޅ
-N�!�J��� A?Fʱ���������M��>��	xa�L�����;w���S��W�=~��R#�T��6���K��X@���J�Pc���+v�����*�N2G�����$ؽ��0�  ���{��`��� �#�i��8f�HXɼ�0�J3{�?��J^k{�����a[u����):||,���Ǹ"�D���W���D�q<��,��po[�G�;K����xK�T����^��JҖr�|�/P[5v��
-P�%{�e[Ԥ�h�>7�����i�-y|L�6���ګO(�r�Gs��7��v�v��Pk����\�w��!��ؔ��I�{R�})����/E>��eI�@�|(�G%�CdX>���k^��Q�t��Z�u�ץ��1�ף��Z�����s*�>������|��;(g$
-�3FlHuI.�%���;AV$����S�!���TCB�*dN�Cv�.	��^���^�����5]?7Ϟv�գ�/f���{+g�j���_'bJ���J�vjA��_H���>�F%�!��!�&S�bJ�q*�����l�lI�\�Zs@���(�V;S��ܽ|$]D�RH}�DF1ӷNf+C3��<s�[�v�6��0	N�j��!�#�B�0�Z��q�+���j��a�*n]��` ʲ2/����,���`݂�����d�X��ω���*Z:�a���u���g���
-V�)�i��b�]�h����?w��X�,QvI�N2��i�b�y�3?_D��b�E���+ԅW���jB�Iw����%b�K��p�S;C��b��������3;c�,v�[ W���H�b���uD��n%}�{�X��J�@�ŕ`��*�Ҹ�ϦU�v
-8T�,qT�L���P�G<Ρ9>�����nڅ�~��~.���)�� Y�1�"��ow`���L��@�"��Չn��7�c�<ERU|����3Qw�\�[r��v湐�42]@���牺}f#�[
-�/i?J�q)����K���X�Jr�(9���%G��ßK��r�9���#G���_Kڱrd��V��ʑ�����v�Y'��"i����r�6Q;^�� �K�v�9Q-k'ʑ���v�9Y���N�#���u�v�9U� k�ʑ���I�v�9]�"k�ˑ3��i�v�9S�!kgʑ���Y�v�9[�#kgˑs��y�v�9W_ k�ʑ���E�v�9__"k�ˑ��@��ȅrxX�.�#��
-��&#�#y3$O��@��F��7C�4m��G��{�H�Ol[6]{χX�.7��e 5n�N��qa��Ը�t�N*��ScCJ���EE�W�|�5�.lfTTd��9��m�k�o�y��%������ܪ.�N�[IE�{��~@�ݮƥ�bw��;��]*��cw�r#v!��}H��"����&�?�va�0��b�9y���������������"Ð0�d������t�]��7�6�T~q	?�ǧ��i����|�Ur�jy�N�j\[D��v���A����4x�bq�0"��Jv!�Uс.�������ݯ�8�O�H?C��T~��I��1ݷ}R\Ў�ҳ��rx�<g�0�8<o�0�^03T0Ë����i��%�Ә�d�<�%��X�,�;Ļ�9��.��
-��P�Ih�N��G"��U�g��,8=�8�nfx3�a��fx�����G��Guh!�-Q�=��{1��	W/�gZ��Za�`p$���_5��=�����G�or��uT�~St�z|^l��x�V��X{��V����Ou&��}V5A�H�iGz���~=�x@�y$��E\�|�> 2�5�p\j��f&ܰ��n���9O�y��,]�����r�s���?�By�谳��]eԸV[�4��!i��(
-�,7�Lhw�B)h�]����~+hfv?�*�.X"�b�J#3O<���]Q��&��n:�v`c���l��2���8b.Z4bnˈy �]fX�X>�s� �� �i���$��' ���L�F�j$6n
-�@Ȯ��!p�nO=f���t1�]@��DIu��!��v��>��r�k�˽��V�7���Lj�1��u���Fا+����a����[��:;GT����F_!gȹ��0J�E�__�>?�>f��d
-�Ģ��r���p�,.��dh,���$�;��h?e8e�P�H���u�*>���*vt��n�u�-:�t��>N�*��i��vG�i\�ǳ~�}�Y\_� �~V\?
-aW9�ƶ�u��p�㥓'���[@�P8|�.
-%�<��n<��
-�c 
-�x�ˤ��L4���[�_X�_���� c�ɺ��L4�`00&��0&��1:��dL gf�H>�ԓ��LD��Nqdᝢ�t'������%.�+�S��` �Κ��
-��P�2��Ow>��N�e��N<1�'ML��}�Mn�݆L����Cs��Ȏ������TC�G���:^
-zB���ވУ���zL5�f�[
-e�N�dac}�gڝ�g�&1���.M�)'�i��\Ɓ��f%�	��3��绠de��%`�]���k������@B�,������E=�xOt��x��Z'�k�s*������+�T��u��:�vǉ�M_v����^���[�Oɬ@+so�>}H�L{H�<,�������#rx���yT�$k����b��T���y�;�j�a��I5�,�K�(+h*w��R_�A�ܲ���&	5r����ȹ"�"�h��/�} r�H����P'��E�.�Kn�v��c��4���4{Lҍ����K�ȅS��{�����Rr���3r�{N�/)���ю0 {��pOgiOv��.TG*��=Kҵׯ�8͂�����G�lI�]'�ڣ�Զe;k_a��R
-�G����rC�>�ti���1T	���*=��3r��K��
-4�R\2�Aލ-+/8�dI<>]< ���i�D_Q�M��NӃ�R�Q��/���]�73g�Q��V�E$^�.l������h���h��=�9ۙ�Ob李#9��� ��7�:�Q�C��]CCx�����ť���=�9TZ�vl���[G��Լ�[Y������@�QB��[�I<x�һn�=�ӆ/��I�=ƴ�˧}�V�b�X�Ҵ�u�)yFɥ=%GF �Fp��Є�����~|-�l#�31��=_УOc�tQ�n��&I����M�(��x�$��|>��
-	��������V�����ߢ0 6�+��K+�ҽ݈��~Ҁ'�t�w(�c�`<P�+ñ��x`4��}�<,��w��eLDx�.4���E[kG��6[[� ��zlM��ah��FÔ/b͇����-�����-��t��|�����.����7e�7�⍵{���o�6k�M:�l�y��o6M>���x�m8P�t��e��yὓ��j
-C�l�+��l]fC�*�����+KE�󊠼}�/�a�cuIq��X=wY*���"y�Ut����!���a�0����2�S'�k�q�pq�F����A��V�$�~�/_�D
-n�~�[,������H����!�QzX�:�4�p �5�=�� ��Y����u?/��v�g�T����X�^�J��m�QN�?W��/T�j$�~���j������_�J�%��b_�=!jiaH�5�M۸���*@�W�_���Q��J���y��[L�c^|�i�a�7��2|�{�	(
-ڰDk��	��q�� HO�߫RL�L����J��!G�#p����x��ZCh-�t4,���a'5�ng�l�pѳ��w���t��
->�}�ˢ}X�߲��}�������ԉ���,�������n�A��nFJ���� ���2 J�w�K� �G�Ad�U��P4�r�˄O�C�&�w��[\|��
-/����+>
-��(�x���(��Q*�򢪉�:<Je	�Q��(�`��W��������L��$}j�ljB8#�����W�h!��H�h,r���C\q�3B<�<�x
-���� ��FJ]<@c���o�q�!�ߖr<\_KnF���l��ք�K*D���y�>^��WZ�
-�7ǟ?X�����������´K3Jϸe�e��e�hY����c�c����౏�{;	%�̭Z5>����q��Mg����|n�ކ�-�=��u�����_��)e�?oX�����Z�����e���F�`�G������V�2�9��]<��S�K��q��߻�Ba���]}�;����Kf�mkulu{��Ө^���[_x���Ԡ�h�k����~#M4�0.8[\t�mq������ph�\���2�����L��)�����R��X"���B�1�[��O��9�\����|3�~�kȗL��@�f%m�,i��%S�a'�1_�{�8/��'R�PtlpJ�|�1,HNG]>U��ǧ��.n���z��*�x��xMtLq�����w6,��L���{��R�Qr8~������p�
-/�����kyi��//�v�� �Zi(
-��'�O�e�*?�?'+7�
-Xg���r�\~~.�"�7P@��P��D�����҄�g㶅��F{�H��(��w��;�<��^yɂ/գ0|�~V���1	��Ƿ���Qߎ���Q�o�۱|�&��m���8��Z��m�R�D��&÷�zREUN1j�u���\|��
-�f'Y+_�ƺTى'���q�rH1\D1>���Cf��o%��?�S8�$���pJ�������@6Y��X0���HP����m��	��Yh����8��8���2���D�8���x�{�K4�x�äa�����q�qz{?�����~����.܁_�f���/�f�c�����x�K����x�<����8��wb�:>:~��~�r�V�ձ-��8^��8^��k���~�V����T=4�l�:ώ�����3�ϟ�_m��?�O���$����4���M�w�j�/�2�R���o#�K+c�62�u^��{�K�U��	�D��K0:��wr�X��g�G�Ȝ���!��Q8���y'�f���Zނ���b/�};�����R�G�2*�Y/wϢ�����ى�����~*�md��;p�DP��U�k�8	~��~�����֍��.VN� �片�����v��8�>���r�F�������_�����r<�o��U���w��ڞ����'�K�xQ>?w������9�$꼐��B��X�o���ʍ7�a��[x7������V����l��u@X~[:�����L�P
-�����m_X�o�RN��ؾ��l�d�ڶ9o�z>?4oU�f�[����g�7>a�x�����8�WK�v�F���y%�ڦX�c}���<�Z�%�~�*�%��.����m�$V�Ǌ�gV�������4�
-��v *�4�w��Nj]R����
-��ަG��G��Ɏ�m41kn�`�2�m�Y0X������&���Q�P��(׸�r���F��m�38��i?QAZ�H�o�
-t��9}導���rH|��|����/�q���;��g��]t��ܔ�ŷ����:>�^?��o���~��u��Y^�;��	���,}��_9 M�>:��������O��5+�(�������x�A���X^����!���ck���LR��6�(*K��L�
-un.�M��U��\>�tX׼\�@�?�_���\���3�Z=?S��ְ�n(��Xh:<��$i�,&Y�@+���SyO�����T�O9$M�v��~�]�C5��~��,O�U�lkf^������^�&����ؚT���K��B:���N��bA��b��l��0oɒ%��Jdclo7v�I���'RIJ��� �~(,��(K�k�fH����2u��9؟�M]B?��T�P]�Z�)�kF<�P�~	.��~��ՙKx�AP�
-�W��0�{�k����mL/�T��%�S<ӟD"�X1����.�	��Q���30��$h�̇���,I
-/��f�}��N���b[˯H�
-�)��_>uu��V�Yi��6�-�*z��9K��F�^�J(�L��,W��{WW�JN��W����b&[�w�aFSI�Y����5�VtY`!�t�m�p��Hy���՟�5�1�%�F2�Lf�e�5ƻ�Aڋ+�±�����M���S�:Z�[E��gf��4���(�
- ��`�uu���X=��f0Au�.]�T�S$�r}D��.FƱ^�,A�I��7��#n�-<��)���Ez�m����(Z*�.D��`��`�`�J�3���#����˯q�]SL?���f��-�]8|
-e	b�w�i��U�T?�q����M��{������xj隁Լ� ��|�c���8���T�豌�<4W̤3�|�%�$����@��ų�:v@��`j0�-h9������k���@/���t��˦#~�ʓi\�1@m�i���3�t�^pҐ���$����J4z���,�Ŗ�bG�G�*I�$S�Xv@�qp Տ�'yT�s"����1����iZ�@����u�r7cqv�Z�P`�C���j<2�C2����?�_`�Y ��v���Z&TԨ��ҤmY�3� Y&a�pb����;��E�:,Pdg��#�����$�)�)_6Oe9ܛ�� �|�w�r���Pe�yb�8�Ւ��̈́t��Lj�>k�)h5���r�e}��Dr���9#�fc�����%l�"��Z�R&N90`;��L�
-��>�����MN@=�<q �H�x<�W�>�}���b6�\-��ĵ����������H1�bEVoLI�7���P�ht~���S �
-t��+�.�4cn�me�B�P� ���0!pp�D���֦�M\����pJ�6���3ɖ.;W��ɝ���,㾀6��Yx�=ͦ��3�@�� `֔��lEy��*d�;%�(qGkw?PZ�9���T��t�u��p�S��,��I"����cx<rf)�/�w��&#�o�e�b��
-ԯ4D�%�q:][VVI�bx���f�
-�����R6�.�y\�b17��s����=>/�"V@ߚ,��wEP,�q�ɺ����PWE[�n���\�X
-Tj�D8� 	@�-Y�K����L:�e
-�ŗ�)"2�� MKMMU@�2+tY5`yK����
-�
-��)��`��� X���ݙ��0eJ>�SؠG�r7r}גVd��v0�F�OLtS
-��>
-鬄��%wi9�f�ALΠ`����s�]U�`�JI�%DI�xY��)8鬨Vm��#�^��D��_g��"��1�t$�;ZЯ��R��!��˜/8�QP %T0�ȥ{ac�IMU�8�~g�ꨕC����e)S��\���ń�'z}a�i\MT�Ѩ��Y���l
-��'(����p>���0A���(!��?�g֢��T�׻�̈́p��	mM�Y~i,>s�����n��A3Χ�p~�9�m�fv䚍v͇��pm�o2E
-����5J;�v66�v�M�)UI���[�-�*
-&��Z�A���VM[mU�H0��۪���h����Y#�h�j�j�G����m Q��t0��Y�Z,t�
-�D
-@R
-ԕk���p���\a�z���l5Ђ��3K=׌�i�3@]U�5�`W�KfRt0�tgp�Rɮ��h��(7p؀ʿ
-�����B5�ˑG����,=�`�������z+��7�(s--�X�Y�b��ʃ��2;�tպ�O�c����|	���&`�q6{i�l.�֭����p�dd񯑊?�YP�G����v�>��؄*��I�SÉ)����N:d1l	���L7!� �ݿ�����Su̢��z���Ħ�7S�MaT���̲L�l�Z��Y
-B^v>w��nLQ&�د���4
-�H�m�:����u&i3
-�'d?3
-��eJ#�7W!�2u�(4[�t�
-�`�8m34_
-C��ӯ�C�%I��2�Y>
-p��L=5�������]�?��b�W�w�m�4����8��C���s�H6y�g��g�]7��bst�
-f��D6�7`�K:�� ��� �"V�)���̃Sd���A�e5r\6�\a��v��R)](m�o�[��
-�s
-��N�����ݿU�8��@aq��jlx=Y`�g<sv��WDcf�:���0��/��]ӟ��ӟCF��J�;z��r�{F�:�)	YY7ݤ_�= ;bi����~]����I
-�FF������L�����}x��=����)��\~
-��3��L�BRt0�����;l��~[̗L�W,�����[ ��e �f,��f�.�;R��G��
-�+�ҍg���a�����kR�b�Y([k�(�u�\]�g.��������׼�/�Q��������W�
-r"�{�L˝A),���k�F˝|?�����Y�"e��Հ���9���d��^W��RS��R���[ ����bS�� �W{�{����\n���dG��Bt�������1?���Gɸ�j�P�xm@��-�N5�����L�%&>�{�M��ʿ�(��a��
-n3��t�:�
-O�7/���
-M�[�S��|?Ǳ͂v��4�"�2>=��9 ��B�X@/vP���[��K��d�_�W�#��1֛̖�V��I��	V?�4sҬ�Wg
-��W�4P�)�@fu*�a5Z$���>
-����ŵS�[�~��~���w����\����(����;0��1%�&�z[Ҏ4���f�q:հ���m��,O\�oK�ء�dj'[�����_�o��t<7�ti.���nH V"2�荱�1��RI�x���,��x#uN6+��$�qٻ��L�����p.�EX�GbHAOӥ���5�I	��(��=����jα�Bm��3V=��$W?��w����pin0����;n�f�t!��@�wښ8���31�m��"��s���	���&�s�� Ʈ��f~��&���o��� bMj\J�E�L_,�f*����~�,$�Nz0��	����)b �:c�,^��(�uܐ���Y����l�|�4cDX�*Wc;z>�ف���U"�:����뇵�$���S�(�·�
-�H�t��s."�O�I���Tt������mO��Fb���j�IGB��Vi�q����"��6�������adK�f�5U;���}Ha����x�F������KKŒ�-���O�*Ԟ�R����=�x�}���pL�'Mm�"Cm���FBoi�ǭ�8Kؾ<�"��(>�����3�BJ��}��������Z�k���ӗ??��+�Đ�,�,O��_�X��x48�o؝9�6�\���d䮓#m�ٖ��e�1	���k>}�"0��R3�̬�6z@�)r��fV������ �/m��ַ���cfص�����!F�
-�`BW®<2���U��{�������>sa�1sqȀ�ϝ>
-ƣgR7�j�hx0�oWb�T�.l�7��з�%9�}(�'A	��+4p�0�HƟz�lΘ 2i��+��^Z��[a�i,�砃iT<ƕ�z"�/�<���>Eo����m4u
-K�՟#���p`�@q
-ԷxG�КX�0/%����Ib���;3���;ńy-��M�z�@몞���V�V?b�
-����m���a���@�Avs��X�-DuGC�\��	��
-qo
-�O�������`&g�}r��G$ڃ� �F匀�v[k�xO�U*zd�ևO;蘏l&�޲�x��e6^�Q�����X!K���X�R�ni���m�VA.Z�v�"mpv�)?"p.t�,��7J���q+@\5�wz&cL�&\xZ��h�u4����>U��;us;�����uȅM��� 	�<��A��j�$]Z�|�XV25bC��e�=��V[����E�I!��6��p*���/���Y;������L��6X+�@m�9>U,a�kǠ���6�4�ᖥ�!�SnD�VH��@tos>3f,
-�n�w/S���!�fk�/JӵIB
->T��"{
-�M��a:�O~�#|3M9/Bɘ�������Z�DbL�B�
-�l�|��,� *�82�0�uD\�f�4��2�	|��Z֔b�v�
-���[�ӝ��!0(]c�e��C5�M;�W2G2bdF�ul
-�7���?CE��nPp�/S��J���2FR��K�O����)��u�Q7(%�e�;�@+W�ц�(а #mJMJ�q~�X�n�$�~� H�.#4 TF��)a'�1 2=��@扏]0�K�@�LMJ �
-]	
-[��;g/����I����'O��M'�jr��kX������ނ("�WZM]B�������=��j��	�)tB���+���}��׏���؇S\Ц6���
-}T7����Y6)�s���va4ڱPI��-mTx�c���Ex[���(��`��;m(Ő<� F)nQ�n�^ة${�e�y��7C$�q�ߑ���6�_����N�!O~vXyJ�����o-��q�H���B�  �|[��&,rQi
-b�k�M��?�{n)w"��fj6�9��v�e�~&m� ˦g���q0N�C/2	x��,,�0eG�F �i��w��0�Cd� �Ǝpf�
-"��n��]J,5�5Q�ܞ���s���
-�/Bר�+� �7#�-�G�����t�)�`Z��`Oݪ/*���Xm�>�Λ��ť�2�T�X4�S5�ǆ���LY�q8 M��p�g�)"͍�����t�����9�c��D	�}��`��rfA8�g��+���Ǣ��p��^�8�pZ�?7A���~v�W�Ai쫯�WdA�ňe�$��
-�e��d�C��ٹ��i�'97�I�
-dEKa+>�06� /�D�uj�G��#�rx����h	m�)�&�O!���ct"�G%����yN��&���*���gs1�Gd<�U��b[�:�J=5��@�h�3�	A��"I�{5��%'儹�J��"7,^�063fߞ{{[���Hۤր�0�K�����y��>��s��b��E�f+;�N���?�o	ڰ�nʄ�N���۲���%l#�X{>�pv� 
-�Z1�s
-G��.����4���Q�m�r\"��[~N�w �BK�T7�5���^:C�����X��DU�~�g�e;y����%�Y��t{��2<-ǒR#2l�a�NVG�Bid��Mʠ���k� Ė-ˋ���%�p���"Ln�Ȕ��-ʳ�.���ӎ(X9�v����rl�"�y�
-W{\d��B"���˻ި��P}!�I瘆p�UG}IrL��D�A�}T��s�xBtqMJ	���lwω��wB6>^��a;Z�E0B�1&��X�w`l��A
-)1$2t&���'pP�����(��ƣ��x,�>">��y���Aq�
-�;�u�e�o��<�W�v�-�A�̄�3��@ښ.�_ښ.��	�G��̔eOɢN�8bbI��O?qj<wЦ�G��Xɝ{FFG�'���F�8	�NZzrBU�+���z�K�)�~.�ikd#bf�-��t^�{6�\����59��þ���z/��0����+�;	�`NL�l!9��a�WH�t[,��XI�46�p����-�o�B��#�Xa�
-�~�D���ϖm}D�K/�W+�U5�I�H��Ƭ�_K�Ǎ��SI�E��zW�Da����GO)夥���Q�T�5!�b�T�"��J�5�3�O�։�d0�Ybڲ���tl89�[�BN[M���W^�	�� �T�@�@t�X!�ֆ����@I�xM���G�?���!g�n��F���b8cꂶ;Sf�n�#)6t�N$���7������,��)�]@��w�����@˅��Ip6��O���E�K�{�N0��1�c�ObM�|}ā�"H�~�}���F�mnE��S@^��JH�b�#\���p�!��rŹ6�hK�,z	nw\������¦�O�;̝��X��<���L�]�e<,�0�_�O6?�h����Lx�Q� � �}P���6�YO�>�2�G�5&���(Y�#��X��߼+�D����z�D�xX���I#���6�\z�����+:�񶱎��OS��q���\�-����(��ֱ'�g䏹!�q3?��V��@�VH��A��%��Ʈۼ�3�F�5$i �Q�p"�GL5I�w`Sn�!_p�R�<=>;b@�>nlW(5;bN�>�x�RG���Gbᕊٌg�Lk��)M w�2xԑN 7��,Ri#�}�#Bd�x��H�f�M<��w���؊s�&�9Gx�7����{\G)�����n�����Ti���Î�mB��.C	����,�zC�Iq�FR��:��j�k����Ӗ���\#��$�8�i)�-�[P_~٤d��-��^/���q�-2z)�.�g��2`��,�6��"5d�Ʊѻ��-!�&�.�6b;z�6�x�TX���1��;BX��3���)I<: �J��jذ��p�∏*�>λQlD�?>�a?e�^[��c��
-����_���?޽�v~�5�~A���/�P��<��[C�$��B��q1<��\Qs�J��2��|�r�f�J̡R��k'e:5��И�Q2�*en��YRgΤK�H�܃��Ŝ�"��$`����R��K8K{c���XR�������@�%
-".k8v�̧F3�L��L��ĒKi!;�c��b I�όg&xD��������,)7_�L6�s���89OH"8��y2�c���F2�ڔ9#,�Qv�";`�{DJ&�)��UT��.�zM�#�l�.����}�,�.���g�Ɣ
-����|"Ph,'�w�(iʒڰG���ƕKs3�vtOx�KJ�c��k�i���Ήl��R�)�Yw��������r8T�-�)�9c'8���L�RF��'�`��I�$��zgAz|1���'/��Lm�
-�t�7��kcuz�e���R
-:��^�@<�"V�6���/�n�9sq^��J;xއ�s�{��m]:�?�#�J[f��+v>�yWٙ!m�	���(s��&"���m��ˎ6�^���^�"�ھ�%YB�P�X���j�ׇ��P��4�f:y�7�X���q�tF�XwY��
-�T�g�@fa�P?���5L3u�=`�A��y��?���2�X�F���
-����a�e�<m�Z�_�u5�(K'��rd��
-�d=E3��D�Vk�*����a�; !)0��Δ���$�`�7������U/ú�c&�(�j�򔎠�d˲��Ŗ��G@��#� 1[c�-w	�d�%�ţE;S\���+�s'n��O����jm��������Bu13^.�p��X�b�t�buvbNKXi�s\˔.�ϗ׫�Bi�8_�F�������J�X=�'��(bݞ��eN�\��;��$`�ݾL�f
-
-A>���$d��l�e�0���s��?��������I`�����0�եbmu��Z\���������nYB�!�o�-�)l��c`�	kx�nE��Mb���)r��̈6��D�Ď�����_Q(�J+g�K��&�T�|.Uj7b�7jK�[+5�Y\����+��r���͗��kх�R����_�Q���6� P���%@�CaJp@��R�i
-����=_
-Lֻ��=���\'�a�g���#�9ΐV���?H�My�ޥ 7 or%Ӗ��stP"��0:l����>)IH�>J>��8%qc���²X���ZDu��z������$PqVO a䎈�ϕ���1f���P�E+��Z���u#Q��A�G!�]V�������XM�X��� ,��*�B�����g�����Z	;���Z������ 1�O����sW
-�Ѽp����W�<D�����4~B'4&v��	�̌%�	�{q����k'nvFN:#'���!;�PG�!����[a��͵�>Y;^;rĒ2�_Z+��kp�&.2ƙ��-�����)w�5��%�=��J"$�������;;	(
-�|��K�a��|9L��p�$�6��Z,D�����|D:N�4�|��abXP[r�b]i O�r��M_��h�Wt��E������/�U}���%x��ղ�����mn����M����J�K�V(޺V,V�*�u�N��%�ZV�	D�ӵ �2�� ��qDp;�'q�_N!g�^�]l#P�#�~�> 7��F
-�V� I�����s�֢HP�ѩ��������m�0N+�ǚ-W<�l��.�X<�)}�U
-)�N�ۯ��K5����""���
-ǵ4����_�m4$�Hl�T�ge
-�������#��HC$�JC���e'�?�GZh6�\�hc9h�n �=���gE�Ȱ���`����b>�g���Y�.y�NP�Jy
-�%:ڄFt�AX��� ��� ���z4����������K�D �	AT��&�qM���ޏVח�j��J	O����ܥpb��ۂ�BV<��%k�G�׋�H�kzW�+Eov��T�g�Vɱ�M1�A&��&l6jË���a]Y,-TC�	g�V{s�̯�������E���9,^e�^X+/�j�W*����B��N�.��f6U�`Xߘ��U��U[��>6|�6~%F�(
-�$���l��af.V=�Z��+�X��;����
-][8�+�t��_�%87V�g=�֥E��J��K�T˻�.%T�����d�E6w;����ŵ��Z�~k��q_r|�Z]�9X*G9P)�)U�D���A�I��Rn¿B�9hӲ�[_9�ȗF��	+t2.(�\5|���>���ix$���":����[��Ns�Uiw �
-�����俽���[d��	_l�K\����V�V �7QY���H�Yp�Bk _��^̸�{5#��R�'iE0�W.�Ya������r�{�y���H�4#s�5\���*R"W:%�Y@�5�q�(am�k�
-��4�����@�BP0bR
-�Qe&�������j�l&�G�|����
-��Jq�P����&�7��<��p|��hQ���RQc���1B�>�jk�3px�2/�+H�///��H��9�+d�k�=Dʍ�����������Jo�_.V˅�P�#D��,�p���LYV@Y�~t��#�
-�	h�#�M��]Ȃ���t���a
-Сb�r�R-.�5��T�˯%�@@��6�1иz�Zi5��V^_)L9!�3�2��׊U$W����Yؔ�g�5-�`��m�jyu}55
--A��)����o�����%@��rUP(ϯ������J��
-���Exf�i)+!�	��o+�0M;!�|X�3
-}DԂ�$V�xfƹ,xD©St�p�.uy�Z(��])�]p�f�B�Ckgǀ46T���4(�N�ϯV�a�b��I)P"��������!w]�<~���b�����
-�����<zC%��HB�ɴHK�h͇p����hB^<)�|�z���V�Ȍ��������j�_V;\���!�j�/������!����0t�
-V�p���)��WRNV�:,o�� '��=b�m!-�#S^aE�}�`.!�M��0䈅���l͝�Çv.�$ySc��s����5z����Rq���J��	u��d��#�m<>_��
-���|�~�{�6���B��(��^�����������<��~[ko�W4��)�;lK焜3�36��p
-�����*�N�(��h��M�v�[[��+�	KkC���b��d�e]��C�������vqO�������zs�����K���!d>9���NZ�p�Ѹ���Ξr��A�aS��lwG���2�%~JD���U�	���C���Wt
-�E�Edd���&d�&0G�;lC��sY!h�� �:��>N$�Y��Zҧ�KN'=N��N-�i�nw�	iR��1�mM��%8J�(�Ү������E+�R9U�^5�X�e=������fw�J0А?I>�m�)G��NE-9z��>�=��u���z���B��dsȨ�)�k��Xy���,.��[k7����Pr�c��
-�IP��#"��I�����m�By}eG0�e�E�xnD^@Y���j�!Ͷ~+[���ˣ��l��v{��&�\�v7;��u_#Ӆ]�ք<W�3�*��D
-�7C"�G�A[��2�cIhfP��|Ǔ<�\�ɕ�
-1�j�fd�x������RԶ9��W���+��GF\�~��n��^W2����c�M���������ݒ����#
-�>��O 'C)�f�/P���$h�L���t�����r�x�$
-�j�����.s���!�\i(g�×Z�킈Dr�X�a����1+��W朱q�AS�1PT�8g�ve����;:�'r�T����:ќ;*��r�b9w<*FZ8j��F�l����F !�>�O��9"�~-���O�����B�Y��A���/A��c�����g�"v�}s7r�$X�+0��2:�e�4p�s=�rm�)g>���fSN�5,��ړv汛�����j93��3㵌�v��#�-���3e��ToPK;(��8{N���� ��$7�;���U�~R��~а��Gݗ�}��k�]�E�Y���%W/�;v�h*����A������] �ݲ*x *��&�M����>��{[k/{u�R}��&i�Y�����ϋ�dM+�f�����Ŷ�[�d%-&�U�e��ɚ���jB���YǬ�b�mZ��l�m'H��r�	
-B��B���[�]<�3��#i~-���ƫ�]�,Cp����{�Ku����V�ZY"�e{�������F=��0�l�5̍_��s=���sP��`iP�g{��Xn���Oh<�����u���xZ�v"P�
-� ��/���7b��1�ኬ �P�l�����ܓ��k������:c3ܐ����mX:�ϴ�T��J�]Y,�=
-pt�Y0��دnLhs}Hc����I�� ��nqrޜ_Xx8~���*�����Gb�E2ږ;��bS��S'�n���m;�g�\�L�u)+�\�"i��=q�� g$��\Tp���.��g�켺�l��s�F�}����Z�a����+K�0�eH��Z\D��N�� �Tow�òAr���Z�K[ع=��*ٛ�͈ׯ(�Q�ԕ\����7��0�d�b�Ú���C�q�d��E�h��A6J�3�?:m�'k�����-�R��4͛1�]�l����jwBD���
-?��o��s٘҃C��4��eeCi�ý���?��Y�k�1� E���oh�}�ս0�J���C��e���ωR�͛Ҡ+�k��[X���*vh(�]�
-� �r`���ϼ^����F���6�]"+�� Y�t��=>
-��8��*G�=
-�%E�&Q�fG�wn��r���
->�\3��e�z?,��t���G*lBȒ�B�q�pJX
-��Ԡ�	'��1�#����y�=��W4��	�Ф��֣G�l�U�^�3'T���٤����S���p����J�ݽ��n�+l%.��w6�0_��h� O���F6���[�VD�Me �d��ȉ�O`̳y����l����%\q&�v���T�
-9lJ�XH$/+Rt9�&�ǔ�xa*�d��э���s �|ӯ�BKǯ�|{DBh�ڲ�<y*���-������4*t�	�ٖ���+�;#ļ�pw#`J������[E���KKj��o%G�����Љ��I���0v�t�
- ��p��l~��IY�K���K���f�c��A�_���ag
-˺�/Q��uX������W�m�XO�ܴa"�߀�3 PBb�>~a�}",��F#'L�qR���C~��k^/X@�mz���ɑןTvuAnl�D 7��}
-��^)���Ʀ��ty Nm[0K�^��Ŗ=��ݰ_�Q����Q�ɲ�ڈ���,*��ge|͕�&uP�9��/\;Ba��ˎ��H����C`���� �7���'��q�#�]@,M]�X��<�Zd�n/�4����h���9�b�3��1��T���_�$D�pA��S�p�&��� 7����O8�pV�d|�9����ր�@��w7�n��j���&]��?m�
-<~ж���p�5G�V��;X9�`7�������ji��Lu���0���sHXV�¹�X>�ڦ���,�bK��I	�Y�fx�˛v��C�|�z�+���b�tX�v��4$Ċ��.��/[R�#���jd%�}�z�t�)�L{�+
-M�%i�e�@���� _����)��z?�����83#Z�.�4��#o���֊	z��m0$1����n��E��w��2��+��,(�S�N�Ź?4��"پ�̷r�4�R�ז�^��YdM��x��l�V�>��O��ؼbXu3�!ȣ����	<'N��6���mZ���J/zi��^X��a�eB�Ӗ� ɠ\�r�cڐ��lʆgd
-F���:c T��+B�rl�X��Yx�UDi4���(%Q��ۛg[��蚸e	Y
-0ì]�̅+�h����N/� �+0^k3î�$X��0�oN� ��7a��Lڷ2}�e�𜇝�Jg'�ro͑�jǾ#FT���!�����uϖ�"S2�}���|��͐���h�b~RT����ʠq����)�$E/ڐ�e��V}P!%� �s!��X�Ȱm��zS��,���~�C*��[,c�
-N����0F�Ei���u7_w]�Z����;Ec��ڤL��C���F e
-��;���ޠ�n\Pu�e�wn��Kj��6L�q�ڬ��m��R��0PwMu��nԭ���[�j�T�C���z{_�����Q�j���;ꠧvխ�jn��j���U����݁��Vw�����R7�TR�jk��Zj����u�=P/�Ջ]ukO���;�֮����7�;��v]��R7{�V[�1՝=u{[ݾS݆�ռ�n���;��P�C�]uXW�-u���@���NW���l��=0���6/�;�nW5jcO���������sԳ�S�]��z箧k�<������1����QW�j}��M���n�@n�MhuOݼݳ9��P/4^}Q��mhdG��Q;u���v�j���\Pw�ԝ���S�u��T�-�c���v���ޱ�����jBO{�i��P��!4�T/��K=u��i�[����6=�K�-���؝=ݦ�鶡/w@_z]��p���ly���gx��s��Mފ�~,��o������#�D:��Ig��G�צ�����~h��^IW���s��Jwҽ�����K����7�OW��R�/T�/SүR�oT�o�������L���w�����sT�y��"U�CU�U�kU���Vտ���P�o��wT����7��<�=�o������w�����{����ƻ���v
-���
-�?��
-OO���'�����g��g��焠�����!��!�M���?2>2�2�2�2��9^6^��/����;�ƻ��{����?������'��s��|��B��ƿ6~6�1�1�џ1�/��{�>b���jD�z����F���������!f�N�x{������1��1�C�W�x���?3>��������?�����������e��gō�č�ō{�Ҹ�r���������>�I�y��D��T��L��;��=�|>n|!n|)��r��g�k��f��v���^�0^�0^����;���	�}	�c�A��1����n
-�8e���3��c�x����)�1��SƇ���ƴOO韙2�8e|c_ß�L?ǿOH��=�����¤��Ҥ�2�!i�1i�
-�N+��x~�߾��K��z��=�����^�l*O����~�s��$�f`��y�7�T�=�x����=O�b%�gx�o�C�>����B���ʳ����s���{Zy�7�f���|���h����'(�z�p���i��؋�r��XC,�N�i�%�e�����W9�EI�̋��|��~�����B�^�=X�Wy���J��������k�����B��[��(��%��:ޮ���C}�w�7z�� ��#�n�M�7C����Y	��J��ٷB�'��yǫ�������.��Ay;��`�+��/+�;�����T�gE���;!)�U�]P"�n��/Л�x����!V�)�P��PNcw������ ��+��ث|W���{ʟb0�&������g����������޿�\�}�7�c���导8�?U~�|��Ao�����BN��3�#޿�H�.���+��_*�ǽ����䗊r��c�~��)H�G���3^;G�ɪ�Y/
-�'��eU��)�<����tx��3�y<�V��sU�����x�b/T��/��%�����rx^�+�y<���5�����zx� ��y<o��-�����;��.<o����<����Nx�ϻ�y����v���c5�BU
-FC!���0�������f2a	L��
-�0
-�T��PJ8�8}R�tB�5�,��0{.�<���@�.�E����n���}-#^N��p9Tb���Q.}�Z�o�Մk�S�����CHo�q=i�7n"�踙��@�t܂MO����m�v�^F	��;�w���Y�kU���~�y �!8G�(i���	8	��mP��i��쳄��<\��Kؗ�
-����k���W�
-� �C�	� zC�K�~q�` "�g��i��8���8��p����H�Q0
-�~���W�'^��xe>��W����0&�$(�b���L��S��c�+�+ӱg�L�k��q����w��`�1;�عq�v�|��=/μ:?μ� �`aM�p1,��T��4����/�WˡV�JX�a
-L5F�{Wśק��c^�	����l�sa̧,N_\@���e���˰�:��:�ԋ�y���\
-l�&۾ɶo.�r���Pi̗V��*X
-N��g�۞���\���|��u��pn��)T6ӥl�>��wOΥ�Gx�y{d�7Y:�������]���2e�iȻ]�ͻ2��o��Ŗ)vw��)�y�;޼��A`��S��`�A���M�,	�v�B|h�y8��Q@H}�g
-��H�HMXH8�p,�8���;{a�d��)0JaL�0f��l�9�Fύ7� ��n!�"�Ű�ƛ�,�W�_e�I[o��
-��w���|w
-�0��t��b�A8f�l�C�\��ɻ��Z��E��a	�����!�w儬�~WA��M�����*�W�JX�a
-��>�z�a?�8��G�(��pNZ��5��5]�y����x/[�+�\Y����-W�m��c�ʬ8W����u�T���)rK�6�ޱ��=k�䉁z�1=���f��ݙ����n~ө��|���[zC�KZ?�7� �|���f��Gh�P���a��F�U 2Rd��h�B�|�l�XcEƉ�� 2Qd�H�H��d��)"SEJE����5Cd��,��"C$�Nr��#ѹ"�D�,)Y(�Hd����"�D�E*D��T��Y)�ʭ��T�R�i"���Ւ�K��:��"k�W%�Z�ֹ�ʇ�����&m��V�7����-��5�&�v?.:��j�Dw���-��oL�m��8����f�,����bш��"G����uL��	�puR���e��)��9#rV�$v�s�9&r\�d9/r�Fv�Z]��Y��B�@Vm��ߌ���HY?�R�~��M�["�E���'��}��!�e�Q�c:�$�N]��8Eߦs��`&�^y	f��`��%ع*��.��Z$��XN��> ��H�d9�%r�K$�d�U"�D�w��?��'��j��0��"#D�;��2��%2Z�Pd��X�?Se�2U���x�	"E�I�;8AV?	�TM)a�7%�LSSE�FR!��4U�A��R��T@�/����.��i"Ӊ�c�1fbLc�+���Ȭcf'�������b��/�@�Ld��"��"KD��,)�Y.R)�Bd��*��"kD֊�Y�`g'8f�<r��6& �D6�l�*�Md�������MX{a_���O0Ρ�}4�$#<'�d�I>Ex���3O�K0mϋqA��%�.�q%��UW�]���f7ĸ)r��m1��%v����8�x$FN�Q�1�`tM��n��.��&�'��k���Qx��0y�{C/�٨�H�"E��"24�$K4����r�<�U,F��D�G%�g
-�5�z���0&�$(�b�%0�B)L��0fR�,�5'�,�}�y��\�zA����M�Z��,Y�h�%l�ʁ^ɩ �����VQ�5�D�J��IW�J1�]�&x�1"�"#D��-ѬV��F�L�J��{fS�Y��P�V��a��L4�n��"%^��7�Ib�)$S�D�Q�c��f�:$rX��Q�c"�EN��9%rZ��Y�s"�E.�\�$r�c�
-��/܀�pn����<�G�ӄ�.�
-��*U��\\=��2M��R�i$UH�t�얝��!љ"�Df��y�b�'�v+�Z6�#�sE��Y R&2F����,���Y"�Td�H�H��rrT��5R�
-�Y%R%5�+�Z�kD֊�Y/�z�Jmk��&��"[(w+�ͷ�g������]M�^�G�ڋ��%rW�J�61��~�v@����8��PGE�{�!q�ձ&�:��ڟ�l�m�Y���8��Rg0�6�s�<\���$rY��U�k"��Q
-� �C�	� zC�$6�+�O��� ��"�ȑ�%2Dd��0��"#D
-DF��-R�dN�1I�'2^�(iAq�1�	K$a�H���$��c.�3��jV2[d��\�y"�E���,Y$�X��D��l����E���������,�r&m2��	�̕d�$S����D&s2����L�x��ɄN�s2��ٜL�d.'S9���DN�q2��Y�L�d'�0��]T�)|��I�Z�dW'��y���{iEpR^���$֊�Y/���jd�1Wզ$ds��[������%!���&9�$S�v&�jw�����l��ߦx�ro�i�/�HJ4���$��a�#I�:*r,��Q'�:)K��2��N'!gDΊ�9/rA��%��2��Wᚔ}]jV�d���d�Iu�["��p��=�/�"S}�z(�#*O�(�s�<p����C�8��dz�z���WY���Y&�Td��%�A"�"k���c��u�#yg�H^�=Ry$�G�����0]5����M,=�]�저6��� 2T��u����������p�<B
-,�^z��h�B�1"c)vL�_k�GOq�Ɓ񧏞`�8%�b�X���2��bm�����E6����A��"����Xd2UY-��|1�����@�:EJ$�%�.�0H��"�U�<��#�R����p�8�XK�ſ,�)_
-�.rԇ̑bf8�3v��~zv �#2W����Q3�~z>��r������Lr.Y$�W.�����@]�	�g�!\��VL�J�ҲW�Yka��
-��"�"+DV��Y-�Fd�Ⱥd�_�lD[_�i�R'�[�dsj�&��z�fg��	���Nc��A�\b;1*�؅�\���b��X!F�PTC��^�}"�E�d��0��p�
-�`8��	�`�P(2Fd��8��ޝ@��)f���<�7�uQ
-R�b�&��ɪ�)�SR�2#7)����Ez��L�Y"�SL�90/�,�edZ(�"��b,�X*�2���T�b���T���MW���)�R�Y'�����(�Id�Ȗ�rk�Y�s4�C��xd�X�Dv�l7���D���K1��S�SS�}�����N�{B��)�wJ��"gH?+�9�b���)��]b\�`��D��1.�U��A�W��:T�
-��ɸ�u"�pn�s��Tdɷp�w�x*D�S|%����%�L5����"�D֋l �F16��C��a͖�l���t���v~g�9�w��I5�
-����z������ڽ�ڜ�GR��lv,՜�'D���bO���z�ל�g��O5��R�I��j.I�1�R��O!�b����7W��TD���TsM*�}����j��}�"E���4��"]D��t��.�C��H/�<��i�E����_d ��0�ah�����gx���G����ɦƐ4.�<��u��ӌ��fr��~�X��"%"SD����L�.2#��j¤ʙ�f�:sҰ�w�yb�!�b��Ht�X�D�,9/	K�ZF��4�ب�M"�E��W51�t��SAd���%�vL��W+���l��Ț4��F֥1�L3=��x7���f<[�ÄEmŻ-�4ߞf�"�Dv����+�Od����"�D�q�sX�#"GE�����i�Y:8[㐓iȩ4���9�E�t�!2�e�}Zr
-����7�<��#�EJD��LM7٥bL�.2Cd��,��"s(h������s��(�J�"��,!\�PˡV���+I_E��`�ſ{=l���	�f�-�5ݼ�
-�`���0�57sݣ�@d"L�"(��~3ϙ�Q��̗\ܬS�L�i0f�L��a.̇2X��LSKD��,)�Y޼�߫DN�4U)�"+EV��YCAka�D֋l ���)�6\&ͻ�m޷�K6����Ͱ��v�	��
-��8G���Sp���W�T�
-��z@O���/�0�a0���-vȄk�P #[���]�%���Ay|\(�1"cEƵ0��\�[��	@/{_MĘEPLY�	K`
-L�R|�Z�q����-L���Ѵ��2T.tf�0��l�9l4����a��N��^#B74@/ha9e�Id1�X
-ˠ\�"�E*q����J�Eֈ�Y'�^d�ȩ��F�6�0��z��zK�Z"��[`쀝-��[���RgO��dA�,��/��/��*���p��f�sL�8�p��)wN��tS�ia�K��}��s"�E.�0�U�2@��%�,�+"WE��\�ᾨҌ}�Yo�`5 ����p��=��!<���4B���z@/ȃ>����y1�@ȇ!0�È�&��pdKS�-R(2�X�aL��IEP����T(�i0f�L��a̅y0@,�E���RX�PˡV�JX�a
-� �C�	� zC���?��0�a0��0��(��0
-FC!���0������a2���
-�0
-�jXka��
-��b\�N�Z�O��7�0��e��O�O��VG>쑯�J�|ިz����7�A���1\a"``Ф"��'��0,h�;A;���(��0h��8�ùgv:cE��Q`c�:%d�
-�A�3-hv���?�L�\up_u�y'�.�R燎ѹ�����o
-�7'h�87��-�ea�B��.��	�ci�^�I�*%�J�+`e��x���1�qV��6(�#%�n�I��Ϭq:7A֐ym�T9���
-N���٠=G��p.�U�D�e�"���rZ����z��A"�}����;Ġ����}d�M&��`O��H�7�"���A{ҟd�&c? �Cx��3�l�M�{`/��9�087�c�aWp-*�J�Z^��M�I�I�Zb�@|��!o�)qP��{p�]�vC��a�J84��px�!�[ ��;�rF�]�a�`��q0Q�G��9Ö��)ΰ��U�߱~i'3mI�\�
-)��WrS2��J=Ka�8�s l�S�߻��ragf���2l��$�����.܃�� �A5<������2lGm�i�0��v{�=�ˡ�C%����
-Vg��;��'���qɶ�$����uɻ2��4�*�\��i�S�iR�q��
-��"�"+4�Pj �t:H	��0ɰ���)��hs�9��$�ʠ�n>�M�iy&C�<�u�K�:�.ש8ϑ�<'���곳H�	�2R�e���IhFP��$���;�w�܇�0��Q�x�f9�R�:v�}�
-�"�� ���ъ�Գ���J6�2-�Z��2��@�V��4;F��huiv(���4Ze�=�f�KZ�4sι%�Z��+�9�H�`�q�0>��I:o�X���E�sZ��W�B�8�r�6�V��J��̮"\
-#���1��pN�8á\��p��~����eP�}�`�"�
-à��A��
-`$��W�6���b���=����\#��Q|3�K3;�<��瓧�p9��	��LX"�#��~��s(�7�t�0�(�:�Β��6�p��G�I�����	@���9~�/��ׄsK���9�
-�T�n�41�6z�	r�52^���D���il�-t�5�KsF�������`��߂�O����[ۄ��'l���A{�Hߘ��t�rvɴu�= �j�J4��n���c�RVk�8�2zfr�B��4�N)�o���om�����29������vs�c��g��ׂ�h|�=��=�e;�Z��S����O�i�O��;�OK��iاmt������m�`ߞ�}�`{	S�37iof�����ۙ������t��ʘ�is����ly�-���tjG����v�1!����fk("��m�'LY9�y0@Y�ͳ-��3v��Bh���0�� x��]��-�-����[��n�+3m��vE��-��b��S�Fd�ȉ$�(���SvC槈l��x��L�rK��>iO�,�	��=c���O�
-ʴ)�Ͳ�2>�;2\8�XP�L/2X�Hd����C9�lB������UK�ͯmw��鏳���6�9�-���v�;�.��.�ݙ��2������ÁL�=Hx�e_�g���Y�0�Y{<�Y���g�&f�9Z�s�6���1(e26<�Yy��Z��U{��p".e���)�J��'��t����ݩ�kb])�G�Œ_vޖ�{'�!�9;)�9[�w�>������ȱ_��S�s�� �m�}*��䜄,�r�̓����/!3��v@B�}�������mN�	��p�@��ƾ���~��O�ٷ�=� +w��aL��8�L���6vr�_3��Q�IB1��6����a���W�-HliG%j.e��F���"�EF��+�cD�H�8��d�	�P�q��x�	"ˤ]�,EJ�*�DI�$�C|�D�%K���E&���L�*2=�	��D[�og%j;��/�����o7��/�o�/0}~�y�L�_`n����{��.�omW��зI���D���6��Ը��ۘ�y���Pa,��P!�ryS�!�z�3��8�ۋ4E6��g])�~c����[��aM|���`��p��q����M�#�^
-�M� lc�%|:�m��6f����y�$^�5�l�%b��W�d�k0֟M�Mʦ��6�u�M�-�6�M%��nz�M6[�.���%� �df{i⳽��׳rG��"���<yئ�#�m���l��ɶ9m��؄]���&"�m��"=Dz�����ִ�+F������ �
-����W���Y��Sm�ʤׂ��`y�nI�C>O}.���~�f�E��78�oUݖ��
-v�et��t�c�ub��D���HV'�V'��c�!�D�D��ٽ-:�*�[H��YHq;�m���;��)���[S�є��#)����Oi�@����i�?4J>{����Oij����R?�'�ANj��?ҽ�����['�O�#���e�`����vv�Ӿ洣�?�sq�k�� n�`����I�_���S�vB�g�?��������R5Y����q}~ʩ�)��OmI���S?�+S������ݜo�����$����!8�-�����_������J�烿��R;9�1-�P��v�c�܎[�0�#p�#ɿ1���]@5G0���Zڑi�2�X���L'�4�I8%���=��C:�9�9���?�{��ܖ"�i�i	vLڗ���K��5�ʯ��~m�a�C�H��^�Ӿb'�i[��=��oOc7���I�a��xY�-ɰ#I]�|���+Ҿ��]��=[B���;��P�?��������H��'�"c!�|dW=�Q�#;����GvK�Gv)�-�.�nO��i��I{<�Ӵ�5O'�_O�_�'�ӑ�Ⱥ'��"D覸�D6Jt���"�Ud��v�OO�{�7�������m~��?�3i�.Q9��LI����N�=Hkjq�:��l��x�P9�.ʖ�?K[����2�U�9iݔ�����ݕݖ�l�G+��L��)��U���ө����i�Oi_(�'N"q1�(m����+���>���l�X��k�
-�M%�֢n��1�ڽy�B���'�G���E�7GIU��X~w���܌�H��]\]�N���so�H�U+k�֍��4[��U�FԓްD����{�������ok�-�ß����蜘�{�O=UO<O�k�퉲���Ǐ�����I贸C�{�k���+����)"Τ�^ɥ��=ވ�WA��3�u���N�Xs.u�ψloC�Y�۟ՙ�i��3������B-��O~6,����MM�ړH'@�z��فcBei�@��$">�,�yT���$���i����(M{[{}2?�z9��J9=Nk���n��Ј/�jj�Q>��u�E�+��_c�	E"S�h��M~�,ґ$�,!�Ί4>�	��{bf�n<�G#M�H�Z�����yW��p�����m=I�ϻ=��I���t�SD������������vY
-dE��P<+2����/�V|O58��eE�ͳ��G���|��F=/68�|̒�sr�:�NHkuᾺӏЬ%Pw��b����'q�Ê^�؃�9�@��Q��
-��?�ǺK�x�v"��ugJ�{g�8{W�L�7�Ȑ�\@��II�цQ�k4�|^���$��M�#N�P�OFMn�/�w�/qBAx��m�Q�~}+�4+Z��;�-٣�{�/��uġ�V��_x��Q��&+o��$�^�*���NõG���Y9���q:>��OH-w��_�!�K�*�`�׽}Y3�wq|��F�������v�p�t��J-f_�,��}C�o4�Ͼ-��
-��N�S����Uw�q�=�i|s���s�=�L7�����9 �o������Ǽ!�&EZ}O����"]�c
-�{�x~�h�Ic7[����b|;v�h��=j�wء[��̃��(P�ɓQ�����x����v{�@�Yb;��Y���c����a�oy8zP۾�=h�Ub�>#������۝����቏W�/n-_+�ô+�5���B����#R�W��B��V�ޔ:�Nw$;��S��⣱ڶ}��d2�򤇑1B�d��T$���O\u�Yu�"r/2��o���D���5ϳ#�O} ���ț����}W.�������RDUJh]�t� z��H+G�(r��\��?<��FÝG���R��Ƕ����Ӛ|
-u�ga�/�q%z���2Z����c��*Gv;����˹�����Ʌ�q���U��\�'������Q��P�Mux��
-K���mz��L������z/t�逻
-���4p�j�o���z�>r��@�e���ך�"
-?G��u���D��*��b�u����E՟9���j_ſ�=lsG�+����;l�Y'=r
-�$�t�n:��reX
-tW�#>��V�]�W�����j��?�7�
-��9	��<�[��
-\�:�v"�כ����e��V��{�j+�z?���4)�:���N �8�[˫C�;5c�
-�r"Ob�F���V�u��c_���΄�F�2�ܽ�z�ڞ�\<j���~�;�-P����<{�=U���~��K�^�ޗ4�C��/�{�y�{���^���u�wj�b:��Q(o��j7ad�7R��C(��*���(��;��e���!�j�Ky�'��R���a�<TU��w[����*0L�nӡ/2U���:?���3���y�������$}YY
-��c$ɯ���ÎG����xM'���$��)�T�*�?����4��4�B��T��S��(e��iH�t����L)��o��f���l�'gc=5����J��������y��t>֧�c����,��lֳeX�-���X��/a}n1�_-���%X�/E�f)��a��2�˱:�cu�`��ˑ�*�ϯ@��yy��j��5�kk���!_\���ys#�M�[��/oA������
-��Oa��4��������`��,���s���#� G�]9��U]$G7u��\�%_V�T�+$�RW�<���Vװ�������P��_U+Y��@��J���|u��C�]t(�Χ�q��g�� �:�Q�!F�Gh��aM2FuFǪ.�m��"���8���1�MR�x=4���)Q=�)���f*݋|�U/��P��V��<\sT���7�<���W}���h��.D�"�{��.Qѥj�L��j��~m��~m��~m��~m��~m��~�@;�E�1=R�Ts��v򳣵�(�c�X=Nw���=QO�E�XO�%�XM�S�fU�-u?ؘ&#��?��xF(2S��Y����H���憢�B�|�E��x��!W�m��v�0�Z�k�Z�k�Z��u�1�`�A�1��1���e��Q�n�<TDE(X
-*C�
-����`U(X
-�H�Y��:W׻��M��
-6�
-�L�:1q���h��o;�iy����g��Y�N4��]�IB�n��=�)������>-o��cR�9����9Ȅ��:���ޞ1@���?L�8��ab'��9�:��G�O�=�1쳨CG}�RΣ���O`_D���ľ����?�}mG��=\WJ�&V�θ�>���9��:�������w[] �-�:Kp�U�p�S*�r�y	�}u�%���v���N�<BS=9�vg4��E_��j2w�:�V����A#��7C��"������������~�t��{VO}��^�>v���[?]Ç��>Z%<�<�ՏH�sܯ�;;Y������3@wq��]���2���9)�|4�3X�bAS=Cuwt��g�@S=��H4��-{4��)Խ�Ǡ�����84�3^�e_t?t����g �$=�����z�#��Q>�d���Dv�9���)Z%u���0ҧ�Ꮌ��]��T8r�t�g���]<�q�j!�3u!ɳ�GVec���c������g<��z<�yz��g"��z��}<E�t�e�{���C	�"=��-�S]O)�%z��z:�^�U���3I�г����^�gSb����`.�z.��z�뙏g���g�^��C�2<kt��z��,׫�[��[��x	�
-l�wXos}�����Q���1��w;�w;�U�Nb'�.b��J�E��M�Vi����{ܲ��c�*|��^׷����Ứ����.Q�|��A�w��;��>���໦U�#��룮��j���wC���M}2tO��V-N��>-r�W�!�}�]}��>�6�����y������a콃������w��{��������dْ#��(ck��Q<[�e��(ΤX�Ľ$r�cO�{#z/D'A$H� �@��AD!@� @t `��ٗ��3���y�gϞ�����5�_k�ǈ�c�
-�E�/IU`�T
-|+
-������߼j��Jx�4V�]�Ⱥ��▱�m<�c-x�=c�#Pc=�^cOc�?46���M�cc3��x|j��[�g�K�sc+��7^_۠0^_�B�
-���y���x
-�'�qF�g߱#�L ��W�㬌���М�����- ��"'/B����c�lr����Uȉ�*�$���֠J�נJ�׹�
-��짔�C}U~(��]�0���J�}M��r5��r��,�ϛЇʵ�o�u�;e�v�4��i�{K��m�~��
->�/�O�6�O�>�����v�_���^��ڀ||)߃��yP�<$�_�7��W!���Qy
-�"�1�!0���3
-&���$��I6[H6M@�bz��H5MBN3M��w`�i�4��L3`�i��g��>�rM�93obT/�"璉��e��o.t�G�c
-��T	>0U�M��#S
-�h@�A�bkހ|� ��ɻo�!�4ϒ}�U$�O��/}0��͙�@a^wx�.�i9y���2Bxj^�%��W�f�g�Uh��?r{Y��߼�󺙾t�̀y���O�(7�yeބfмyȼ
-�����qgٞ��7� �Cs)xd.�������V����jV���ʟ�E��G	-պS�;����y�;֤Ԃ�JxA���"�kQ _�^*��/�߱6�	��4+�q�
-�Q�������5�1�3֥�VX���n+B+�xG����C֣����#�@�n��Q�1{��W�'#Re���q�َП)�x�s��~��\�< �f�<�rTn�CJ'�Z���npD��*�S�o�4AT��pW�R��xq� �w�}^����\��{�n�Q��(Op���ټ"<E��>$�_�
-�ޒ
-�X��YK:���W<ʿcK9���2-�,�l���\\����zk!w~��~�[����?Y��MPd[��۠�>[
-!�"۵A�1��C> Evh)�|���R
-��K�k�Xk9�8Pd��
-�	 �k�J�I ��*�)��R�Ոb��L��3��`��̲փ��0����6���f0�z��Wb�w[�E���
-����"�
-
-����M*
-�j�k������\��}�U�^2�p�����3���ɍ�@��;�䭏���V����^�#*Y��X��<�>�g�<9���O6�0V:�16q �=���BQ�����Wڰ�.�F�5�?��x� .'؆ '���l�!'�"K�
-9��� g�0b���l�`�m�ё��B. 1�MB.1��MA.EVj{�Y�mr��=X	���6��6��>��A���� ׁ���!7��FPdM�E�͠�.ؖ _E�b[�|	Y�m�eC+�*�+��dE�5���ʶNVbheۀ|����	r'���mr�m�e�o�Z�>C�bheہ���mv�k��������|l;�؎������|f���m�ł��8��-�%�/m��+[8hK�l)V4o �7[*�͛-
-1T��&�G)B3b7$Ith�*`����^ኝ�
-�f���x�5�E�:��@���� w�({+�nCk�eȷA���
-�t'�#�p���Lg�
-�'��n�h%v�E���.Z��������h5u�E+���I���)ڜᚅ����hY��E��_\K�c�%ȱ�
-�8Sp��Sp��I1W+ �������mY�z���2�9<1Y�Z	�9��ΩUd�j5Y�ZCV��'+Wk�P��\�փ�j4% �Ej
-�N�*bѥ��=J���Z������NG�h�tW����ƛ�G��ۚZ���h�W�F�{���c��@�����v��ޱ�7{���}�]��z�����s�^<��=<4�A�B~�v�����vܾT��H;n_�_7���U�<����k������Vؿ��Q��D5cT}�uS�wL��7*��W!W&�y�>�pA��i����:�;��l�է��^�g�g�y��=�j����)
-c�ϲ�9<-�����\V��%����l�lZW�ʦA8�M��~d�����:t�y�<�ԯg~d�*�@�R_ۿn��Q������i&��L�WG�/ژ|�
-�A��Q����G��i#�:f����D�#jb��o�nO���$*�F���#E��L�_`I{K��杤�E�<�E�w��06�����5g�_�m�k�ye^�6K�����m��m��m�j��H5R[��-S��V���V�Fj�Fjk`���D�%j����G��oc}̱�5�\��sm�s�s��3��.�?�W�ޚu?o�1�6~9�U��o�=�U��oq8���.�QD�9bS���8]���]����$]�������TT���h�y~@u���4�{��9��3��
-9����\.�,	3P��r�
-������q�{D�vQ���:��u����C��=7�z��
->t����������w?����s �g��s�+��=��8�~
-��HEU���K�%���-QEV�-U�],����"o�z�{��oX�˼U`����ր���`�����ց5�z��1j��vQ�Ռz/�f4xi��� ?M�F��ۤ6�ʡ����<�Uj`Z�n�%��
-��^�x����+����*��m�{������o�����j���P��M�;��ۉ[�{��~o7��{��_z�wU�`��[X�C�_�Q�ƪ>i�������ao���$|�F�t�K�_c^Z�z�}��~Za�K�V��>TO�s���q�I�#��kS^���;�c���k�^���{��>(H�Og�t�t�Kkk���6���^:���3��^:���e�SdǊ�ֈV��^��KkDk^ڹ���Cox���'�sp��ny_����������]�@�(��/�U���{��ti��{_!�N��t1���_�����.&�^��)>6�V�D�4��.�Ǆt߯�rs��l
-��/+d� g��پw�s|�s>��\ez���i����`
-|��B}E��G_Q(��WJ|���R}i��G_`(��*|��+}�y�*��j}�Ʒ�����P�W�r���!�z�2z��-���}�SM>:��죂�ࣂ��D�����K�w`�oZV�d��c�)[R0��gT~�fVw>��u���o���[I���'�$�۷�.�J��Ti���dI��+�U�(��nQ���Q��5�b���RW����'�7U}S,�}�G���s��oK�����}�o�����#ߎ��L�c�i~���ґ�>:���#��|t�﹏����������K��~��S�~�`�GK�C�}��k߁�ZW�Ѻ���P՗�l�GWc>Z]���q��O�hu���H���l���M�h���G��i��OA�9�}'hg|_����l����/V������hA~��}�R|ԥ.���ʿ�ʿ�K@+>Z�_����G�ݯ�h�~�GF���O>Z����
-���V�}dV�}����u�]_��u➏� ��������G�ˡ/Y���#}���GK�'>��%�?-l��S�DQ3�f(ޟ�}�XE�?M�z�=�O�O���$��A�?)K�gh߱4��c���C�~z���7Y�L��C2�~j�r�Y�YvΟ
-8HGi�X |� ���D |�'9�T��.�N����|p&P �
-��"p.P�J�[�C�KM��V�>˖常�p���z�*��͗�ݼ9��<�Y�Y�� ���F��a^
-�'�0�Ka��<�7���0���{ݙѝY7?��`�M}�<��\��^�f	���4/���Ӂ� 
-�����s0�	f���lp/��ρ�\�0����`x,��<�r5-�ӒX��V��ȥV�AI����rܓ� �B�`r��.^5՞��/�x�Wm�S��!u����J#}L�5y0�5y0�5#���0+t���9�K�P+X�������8t,	����k`Y�:X� +B7���M�*�	V����P��w����܂[�6�:�w��ý��=��p{�6���n/B�z ^=[B��K��`k(]�k��R�x�h�R�Y��>�|=!u%�CǾBtB�=Dg�����Cɴ{�+dx��n������
->
-���Co�'�q(��9Cl��[�n!�߈�mԨ��c��:4����ph���!��f��Yȣ!���>x��
-�sx�Dh|Z 'C��{������c`B�e��
-�#�����Bk�|h\m���OT�B�����̖5l���C[0�ϡm�;���nh����=� ���n��n���n���n�N�C�/a���������V�Xj8L���J�l<]��D8I^���=R��fw�^̜�i^^��#+L�:���*��p��#?΅s���#7���_Oa����pX.��E`q�,	����R�,\�����pX���U`u�*����!����z�r]8�+*}������A伞�Z/�� �y�®z�rh1P��^����5��܅0%�"OnK��y)L	l
-��H!�W�ی����)��l#R��?EJ���T�+�#e��)���l/�`��[EL��a.&�V��w�G�5a����V�����o�~d����I�������j|�]�u��NQ��GK�bu>����%������QԶgD5�Te�X���G�m�l��@��O���w�\Բ�{�uѧ��;��
-MA��B�{V�k<ˊ��gYI�um�2� ʣ.�Q����V%\Fޟ�*��wu'*����
-�UU�v���Bw��Nj��6G�/Du������n�R�-�5�6x9��u�u���ͅ>�!���}���g��W��>��-�t��<���ڣ�_}�B������S���w�3�aQ�}��Y殨��_+;��EI}<�g>�w��Nߌ�����=�����6��z s�b/ b��P�G�z��K��cLt��W���Ax:1�wQlȗ�U��L1���#���65��/D���Q��R���\�W�&��Qo���Ip=��J(V�|�Qg�!��>�^wf��՝�rN�5�;�rQ���;˺��s~t9ď��������Ta�6��D���n��E�Z�~�'�� j<�������(Zg>���K���F�q��`|�<�?��|�$���6��9)26%�ԉ�k�
-��Yat".�
-,�}�E����i`It:X��E'�Qq������2:��N����q~%Ud�ёz��������<Ǚ˙Ǚ�Y�Y�ǷHO���e�[�b]t2X�h�e
-^�.[��������
-�g��hM��\���h��u%�vw]���Su��(�mӫ�m�.��O����9ףk���:�Ft=x3�V�;���F�;�v;݊n�|;��/*�"{���[g��i�ゟ�"��;-�s�Of+�e?_���=���R_�U��,�6�<�n��}
-EY��ᷙ��Y�Y,��n���������#����2� ��tߜW�@2�l�l����U����o���&~1��X�R�����<��Z$)F�C~�����44c��ƀfJ ��D�)�)I�ے�44k
-趥*�=My�������P&\�+Sy�R�,�b@ղ�)���Q޹T�9eڥzs��.՗�̸T�2�R��,T�\j�H�w��be��FJ�E�U�,���2e٥�)WV\�/T(�.�l���R��R�+B/�z�u(��v	�rCiE�n*�aX��=�6d��+��
-��W9ͬGʩ\����Oao���K��5���d���2�VR1��ݲrO\Qʍ�qU�P�Jg@5�)]����j^W6�_�zӭ �7�mJ���wQ ���@�u0J�~�-n)������9���>+����<F�{ʓ���+O��@���C�Y@�)�QR�J@u�(/��2P]1��U���BI�Yzܪ;�2P=	����M��{T_��5jm�(S�ɖ��H���`�%�²,��m�r-�'�!C-�	�Y��|�D@6J��
-kzP3U�ns�5#�*��Z+k���if�|���Ț>���}=�	-V!'H)�le��������>��N^PY���ZT�O��AU~j-
-��>kqP5?�nU�uۨZ�������uǨ���F��ҺgT���F�9h=0��!�QU_[���6l=6���Q��Z�U�5FV}o�o�Ư*A&��Af�[1�Ҕu
-嶺Q��l�.���������vOu�?6�s0�j������4��(f�᷻�Iu�-o��]��'ߞ4�M��M\�&&j��E���>�B��X���5ږX��Z�4�F�6^�N�u�,�(���6�0c��X��e�Y����O������Z�S��cn�同��
-�#! \E�P�ڑ�_�P�?��x�����7K�X:p��nP
-2�M�3+ tR���.*�!M�ƽ�$�½�(ަ�������3�.�D����am��Du꡴H�}��ū�W�?��u�5�ᑮ��;<��I|�����
-�F��yLj-f3m�/�����+�¢b�5��h�eI��W^Z|��PlO"~��Kvh�M%��+%��m-�t�q �s���J`vR*/�w[ �/��+]\*,+�-�\c{ח
-0$a������|я��	~��,�W*)��f��F���M���W�&�A�(f�� x�)~�����~��K윍:��~��3�jΗ΄��P:��U.���{��K?*��~�
-����B�<��P�~h��~a�_�����w��&�H'm�y��_��>��́���z���d}���_H��΅�:�yP�`�4J̓^���P�`��
-$s3�
-$�B?��ʥE~Xۉҫ~X��--���N�^���.(-�yU�R��4���թ�s4�u�Tǝ�
-�"�SD���D���>0Id��L�0=S��:���A�!%l-����s�aU��A`�ڀ �K�F�)mRY�6c�Z�c[�G�.a�m����,]xI���Q����ȄN�4W��̗��o٬l�|^(a;0�K�Ņ����g*�be� k�����J����^[cS݈(����*#�=#�qBܨ�r`���7�IA!��)��1ع�c>u��]w[X��0Z�����T���=ж;��ж;�}ж���ж	� ����{I�Uo�T�!�زt;�$��].Ŏ}�t;�*ǎ��Î}�t;v/�$v�/K��cWJ��cE:�W�_��B����A�����UO�^�_�s��~��Oz߯��>����ja�A�_�����_-
-���~�8�u�c�Z|F�Z����_��)]�Z�[�U���-]����g~�{�;��~�,��tݯ���_������_
-~O���������zw�R��V(
-���?�y��$�|M�q�JzYS�MS�MS�/5kj8���PS�&�i�σ�ҫ���`TZ����^��_'-��_���j����Ԣ�������>�Koh�o��(����
-��Q-��UrVJ�uA>���ۤ���s�ģ��%�}.�xl�y�W׽NT�4&����y�lp�|6���G��^G�%{��l789ϲ�d�1��gd����y�tMb��,����B�|��DY�[�X=�]�06ܮ�˗ϋ��[|S �;]a���f��Pe�`���-\��)�v�����B�
-[��9�)Y(��Î��B��I���Gr�|�̴�rX��0{��(��,t�`�\6���p�d[n�E�E������B�	����g��);أ���`c �s��M����l:���p��~y��-�r��-�+k�l1�_��d_���[��~Y��Ɋe����l��}��l�Sf��d[���]�6p�?_�b;���4��,<���B��]���\�b����:;.�cYx������wι�����.6�%ߝ�f}d�{���~��͚���|7�K~��f�B��W�l1���n��,<��ͺ�B��n�bt��V��}Y~|����O.��F����n�	ܟ]q����?s�����\�ܟ��˞��_��c�ܲ�yl2��|9���W�yl>��/�c/���y�oe�y�Y���<�b{*�m���籭����y�L��uam�?�k��绰}�F�va���~�;��Ytbv�5Ӻ����nfvܧ�ta�9b�]�q��]�Yp�owa�d����.C��S�����?�ݕ5���ӛ�2�,�֕U��we�!��ǻ�o��3'��V��D��,�������³�����-6����Fp����e��- �_�x�+���^��{��^��W{Y����˖�����l9��u���͓����@��]�m�0�
-kI��il8,+a`Ngc�p��f�W`Z��P����7�2g1VP���>.d+��Į�]���҅,��ذn,	���nl7x���X+x泥����2{�;
-1ػ��)���.b����6�� ��T[�Elo[	�W٥"�<���"�<��t[�%l,����M*f[��¦���y��(f;���S�v��M6������-(f���[X�Z��6[\����;U�~"��yXÃ,}�}X̦�g�^�~*+���._f�؂�3YX���_������\ֲ�Rv0ֱ7K����M���l*�n`#aLlb�KYx6�եl'�oa�J�oda+�Zʞ��mlG)�	�Y��������Vv2��ރ�]�X);
-�/���]O�]*e�uU�2�`?�7YH�*Z�i�Y~[�XȾ�
-4��� {�G�Gl9$�Oػ�+����'��U�yA�`� x�x5�&��E�F�키	���`�Q<�����l
- L7���I�1A�e9s}���){B�Oø+�m%�S˞`��k%z�Ĺ��	1>��e��gŲ'���+�����J�
-�W��_-�{�_-����g�ZQ�ϊʻ�?+��9����^t�؟ů��A�E��E���x�����`������^�DqU-���W^)�W�����GZQWy��b`b�%Wן$���Wk�H]qc/�!2����G��Wu�,�+?+
-��z��� �pqE��b�!����+��򽢃P%��[�Od��Wklf��6#Y=��!:��v0Qv�~��SV�� �]B���mZӞL!�t�� $7뱅z�[��1��$�=F�U}��!�	/��a'S��=Z��\��*&"��P!�����s�v��[2�7$�J����%�+!����
-4_���`�5��=y�%��DE����GIU�s"��z"����#�p�Wd�_��J
-#�w���d�	��p��2/�
-��8��REH�&H@���Dl�,*�o�J"!��Epω���vA�t�s�Zbo�}�1�$��6�o���V"�H�,���{#��������h86�2DO�F�� �+���,����6"�f" 9�md�� ����󹡙������	D����7$��c+u/D? ^��?/�*�/.���A��X��Y��WSh'�EȮq�{DA�d@w���_A�z��&��Vdu����,n�߂��,��z�k��$�'����0��\�/��+�?I򚱓��I��:��J��FT�\���}��z]�Q��2�q�o?f�O�� ��<�������Y-�[����ވt�D:`!Ʉ�邒�L+�����2��}���(^�[G�]bY���=� �����\�Q��#B��0�P��<oT��M�W��^.� Y��=��n�\Uo�z��X��ϫ\�B��&%�
- ԯ����o���,�&w��$�r�=B�p7D�Ʊ@'��	Y�%,���sVVu`eU+'���J� �6#GDd�$5�}s�C5udመUE�2v�S_H�(�?m�?��ނ��/$�ȟ�����nA���H�+6��Ź�'�f5��ƛB�w����PU�W�E���KE���Iy 52�m��,a dQ4������[fG�y1k���-:ى,>'��<�r���;٤�|t�i�釷��dV��)�Kv�'���;f��-2=��鋔�e{����`?�5�_����F�����P���>!>b4�$#E�?"%��bf�E�D��+�"L�����yD�ꉜM�~M���de����Y��
-e�3��Yٟ��{�*��"f��C6k���zۡ��a���j���0�H΍e�>=�:`��l+#~A4�V=?�48�X'�ے7�.��糆���=�.�P�ݾP�w(�Ŭ�Q�>��B�o�������bV��ݪP�
-u��僬���7��
->��!j�bTO��q�ll�b#���% �Z1#���pE(f ."@]�E� u ��@7�<�auEC�����#6o�^�,�j'��!Rl��ч*Nk"6Jʴ�()��*质�ʺ�-�|����v)n�iS�>;L���X�y�OĻkŦ���3�lq ~
-+�~��/g�E�ƺ\�1bFa����Y+�2�{�6V�U��$��r9/�
-��4�_+=.Բ��k'�5�ǹZ|�� _��ۺU�ƹ,��8���;t��tT�R0�x��De0��8���$(��
-�X�x����W���z%��#A1�$J�k��9���4/�a��ޣ�����iL����h���:��A4R`o��
-����6=֮S_jK�2$iAx$A(�Y@��*�\`B����ڈÂ��!G��j�<2�bH���$�%�`߲�\!nB.W����4G��ۣ��<_���E[�HkE��r�Q�ݫ���vb𪠜4J��|$�)��
-��D�W�<����S�!O�FY��<(�
-�Ӎ�\!�g�ݲ�y�]V`u�ɮB����k$l�5`P}�Th`D���k
-��a�]wI�N����$��$�ۑ8�$��c��O	����`Iڃ��f${���h�^���B��}_�>Dߊ�'l�}6�>D?I��M��vH= f"׋p��&q�&q I��@�P�C&�D�M�M��8kWc;2|�:�=<�m7w����]Y��Ma/R�`S�kS�ۉB"��E��~��Ma�Ma'
-F��l��M�M�`'
-�,
-�l
-���GD��<|�����NDwg�l=�D?���Q��D�5��'D��ps��{<s
-�;@崟���:1U`�
-w��Q����9�B����)*�;�'r�u���6#spu>��q����ü>ˉ�"NˆY7�Ѕ=�M`x���a6JM�4DN�^��i�����Dx�����@� �"<���x�j=R}Q�a�����m@�^�t&�F�d1i{�F��5d/핾����
-���Z����Nl����K�lI�f�Y�@�g��#�l���g���Qͣ��m+	�}�$�.���j�Z�3�b^�B3yYB��I;�kD2����(I�Ot��_�!�=�Z�!�8FM���n�^߫:�@ԛ �W��{���"���|�/[$6���0I��;
-�W��0B���s����o�����U�<wsBfs��� �҂y�G��%��y�
-��֨�WYV_㸫�Ɖ;�.��X2�ku;.|Ľ���}i�=��<	:,�q@���6�:�J����"�!�,b��>A�:a�������
-7����t1�%E�Mm��$ox�"�
-xc8 te�jIv��O�.S�f�on��RT��
-�@�KU#=Z��xj��3�M*�MS�)�)Ki�b
-��s�
-�K,Ki)� ��kG�JJ��Z�7�6�����-ߨ��@�"�([�L��N��&ߊ[���6�m,��"k��RN�{�h��h  �8��Ԇk\�6���v�r9#�H��Ea�p';�1�U��D�)��.zj�n[!��f��C4h��~䪪�|��JC�����~_V��[֑�uX��~�`)�2�QhZ�D�T����*�ZD��ۼ����Q�T���O�J��/�������s��8���r�g`��9r� AR�.�'�TМ��nW��OL�
-E������>Z�è| ,��B��ES�+\|�r�+|�~
-���h�hTt��فB�#�
-�p?�$t�S��?�'���fQgh7cb��
-or�����7��mpS�C�_�귘���tg��ߠ�~w��~
-B�L+�<1β�����m��G�+({@FTγ�
-�V�dU��MV0'��8H�q8�Auz�F:}#�5��N�N�I��������Z��
-��tU
-��T��� ��"���f�vL�|�~;�	|����}N�d=]]y3u����~w�}��W�%�v���J����p���D�Oh�3�ٷ+�gM���M�)�v�7���6E��U�&��v��Qndϰ�X�>kjM�Ԋu���Ω�E}�d���4	� >�CuQ�AV�\��rN��U8^�3���n��e�3b�Ș�#��۔�@S���V��݁��w��xH`h�1vXJZ&���v��v�x#�������F�@۬�F֎ܑ��6kGoǚ�����Qɺ;����+9�b�P�qI��_᪫_+���;��*�e���@:��i��w�Q�_���n��rq
-���rWt�Xc FE'�+���rO�aV��í�.e�.�ϖj<����o��@w�i�HIQ��Dax�Z|���o�	��-��h��"��.T�˅�ӌ"\�C���=m�=�+���x~��~.��E�d��
-��r����4��:3���g`c��3���T��@��32=�( E8���X��(0��	T���Y7%`d�B�������UFs�$pn
-Ȟ��\�pF ,���@Ѽh^���zz@��	X�J� ��şy�3?~9���}�n(�Hԃ�{eOe ������3	����53�%���`���c�m�[D��WI���C���u_�׳_������f_�bYE{׉��b����~1�A�hO��=�	��k��P⎿z�u!뙣�SLw~㨢����=��/~�(��Sp![_K|H��;���Ь<ןg�fB�L��N�chK�O�d��?�=�]��⠝]�S��5̝tc��⅞Z�z��k�z�f�����~% qeճKp��	�Z[?�h�	�̄�m䏮��Tn�ߚ�؋
-��v7����f����nwb���3�ψ�
-�}?$
-.�p;�3�cݠj9i�_�@+a�;azCiE���׸Q_�݀}
-z/��!e��$���0�\!̵nX�ѺLE��؊@xe 5��ag��9�
-c�g=����~bFnTn�s�K�Rs�q�3���.8�?â�_����J��I�P͍Љ���g�(�:��q��|>�r1;	�Ն�r�d�0{FS�27.vy-��TKk�Kf�e9��^Io
-��#�R��^��P�ci�9�j��XjȌ%�4�RCq��8�*YC1��bk�Pd�����=N�u:쉭��³5re{&z��T��Do��UЕ�p-<�iVT�5�
-�o�%I�����)��/���X��� ~��ɂ���1�5@���U�I�9�ޅs�����C�<>���:��Hf���gȆ�Qa����J�p+�<8�.�=�K]�5�]2�����j !f+�[��6�&f����r��OH
-��	���acX��Eb����E��bbs����5���-vB�����+���SI�,0�&F^
-���9v�ෲo&CȤ�Z隹��vQNs��\(��'}K���dX�����m$��&�D��\�1+�5��D
-HSq��Up+@>2[��C�v���(��$�SV���荝�q:Z ����ޤY�U�U��Yh;Z]Ҥ�4BNn�I[�����+r!:�Й,�/�j1��?D~�oP
-/�����}����>`z�����G�أ��cf��@��<��@������r2P��ɽ��m��t�z��=��E\"�M*�h�*9�����>���E,��
-���x�>��J���ͻ����ݯ�O�[9W�^�B_E�(��H��� �3!�^e��4���jzN��(g��"�e��c��հ~��ջE|�"Q5 2 6��"�H�X;˯����+��yD.�
-}�)兙���B/��!��W�گ�1:燚	��e��φU�����)�?����5g��d:x��t�5�}�?�D��kG�Z!��~�8
-�Z|t^#�ʁ�K�A�kL2ZGx�&b)���9��x5�E�z^Z��jH�����-,E��W�-7�Q��<@�D��$�y	�o�r������'����� }� e�:z||�]$�*��D�|]�
-n{��mC�� fݞٷy�Y%�\6��2�U�J���u��
-��$;��-�zY�݃]��^��]���c쑾?��.V |����R���-⦈5j�c���
-�Eʙ{������;�/���n��<e'iݱܯ8��6Q�sh���~Z�����S��cϻ2=�#qР�$~��;N�GIx��"0Xe�g����P���<���wqGf��F��Ȝ����a�̑�u�.�����-�88���No���]�}O��v���z�5�e�����Q��	2FR�,��m3bo;"�������t����6ʦ���M�x�_�X��}�dq��99�Xl�+V�2�/��2�����Z� �DRM�Qu�u�e8��{�Q
-"th��T@�lu�Z���"��n2f���@P_�� �_X�)��t�	|"�W�V�-OÜI�3�D
-u�N,P���\����q<��3m�(��>7~1��j����古lZF&�aq�>XJ�w%�3�=P��l6��>�x&Gڥ���������S�I�؍@m��@�%#F_�@^�:z͍��PϾNsQ�/L/�/{t4{����'!�0�<"�*}�/2��=F��v��>:�3���%�x�ʡw\9�n4�oc�9��g�G�Q��֣*0�u1�C�݊ʑ�ӓٮHT�����D�
-�`��M�[ƽ���������Юr�F��ゞG���*�<������&I|��@�C[9��N���;E(�ʟr�
-�=~FJ�^Db.Y��x�b��@�s�F"�\��0=@ǈ�eZ�G 29�4Q _$�bH��(6��Hݑ*}�f�UݝI*�&�^3FL<#+w�8�#�C&�r!�hQ�/,���C3�1����Ǧ�L���r捃]�x�,��������_k��Z��	��Gm
-nQ^#yMW;i���%ٺ?N5g^B�>�}Q������WQ�)Y���X��[~��}�׳��nP�_�y�&�k�J��C'�����yNZ�[1/�Bw�O~��LQl����^3{ވRp��C�p�!��k=M���<�O&aa^��7���Z�o�b~�.���P�*@�$\�����N`�	lȝ�>&��w������)�
-e&�	�>���i`��##���E�O74s~#ѧ����Od��O�G�HE�H^�H�>��"�?���_�w�h������)�!mE`2mNGZ"^�ܠ�=���A�$aj3��B�fH-��P���U��f��Bra��[2��2�[ �[|
-&��I���z=$��w�3�d�7Bjq|-"hUf�+E�+
-�W���*�L�G�[�[����V^On_S5��cp�ؖ�l7��d����L�⎴��Xw�z�ļ}m'4���ˊ�ܹ߅������/��o��soŕ�fdFƒZ�N�R��eɦ���U~U�ew���iJ�mu����ʹTIWNvO�_͸�{3��<Y���f�M,��`�x�f�
-�S05��}��{�˹�瞥!���e�ܐ/��ׅ8761G��uG�;yͿB���PاP@�T-(�� >���O
-Ўi���ˏ�{�5�w�?�#�����UQ��e"<�O�p�2�_L�W�9^��+��C d��ᗹ�?���=J.(�^ul�wXgl�wXW�z/L.�l�� ��Tb�j5�
-k~O*J��?�y���¶���n�1Qf#:-PQ��V��,oԗ�����6=�&�����k�4c,7�7�k�k�Y���1�B��U���s�>C�	
-6����Ҽ�����a�����s�!��\�K�'qA��+L�G�N���
-�����\ޯ�wJϼ_��=��;5��Z�\�ߪ�t����]��jW��
-�� oAz����9�����B�<֕��,o��+ŋ0T�3%\�=�_苢�l!��A��k��2�
-�\��5����R}����ҍ�ˀ A&O(����-a��P���rU�����VR�ٳ�u��b�;t�v��Tb�RS���"Z�JnQ��kҼ�,#,nL�x�M��KF!�<A-��ݒ�6�b��۶�c�j��+�^M�ivX6ש�f�R�D�Ǖ���'�)yb��U�hx�׆�[�#�A�m�9����BI���������qhf�������ٞ&k���[x�y��'� �a�DJ)c%Ŕ{&�����1#ʪh��)%մ]Őf�l�s�eS�ȕ�%�[�m�v[����M-Z�y@x"��2e�������I¸4N������d��y����C��sM��}/[ ��lC�>D�B�=6�r��4�������R̒c;�-�ÝIE-�#&w��\WB��`S���#ޥ��W6�g �:bi/<��l����B�T�y�?v��)�Iek��+������k��71���;�	��s�#z@f��9��,{�Zdɠ�砠90VJ���7D�C��O�9�*�e��ڋ2�8�6��
-�P>�l(:�}��!�=	�U�&&WC!��ln����f/��:�@��{�dXTms"(�Ml	Mhj烣C����L��C�tL��Ѳ��]
-/�&Z bq4�=6��T��,1F�S�_)��B�٭�WyF�\�T�y�S�9IEj.�`�:,B�x+;AC�-CՕA��qz?�����q�B`[N���2��l�SƐ��*���^ē�s���Q���I(���'6��K�ж�.�03��E�34��N�3B=�.X�t����
-6+]�+w2T���M�[�Ӳ�z[�l��`NUH9�0������
-_͒<�0i�_ڞk%7)�s�j����W���	ѭ�J�V����&"ryRUٚ���/�d?��l���P���$K׷�ӷ�k�(��b�f'��*[P �ײE5�OKH�AŌy��&ME���l�=c���("]e�xrS�"����ۣ�蒼,���ǪPF7�W�6_\S�!X�
-����y����+֞��e��B��إ�s)��l}]�UD��=�i��{��"z������[C�y=��L;�����~	��C|5��K���9dEC�Z�l�ÊB��ѥ�>+z��z_'�H���x��M�\�y*��@�&I�a`��JLGV�
-�w��X$��aX���V�D�iv���N��\rH`�d�m������L�=�.�ls ����6�`	FEL��p1םJlU�$�U[^�{�^�qtn8�s�a$��|4K-��k��\�մV��E�u�k�Q䒂�9~VhWkZo�Y��5�!E�D�)R�ҕ���5
-P�z�ݺ��
-n��[%tT<�T�roi�U�X�����h�1
-�Z��p�A"�
-3tTƋ(Ӑ@�C �I��rz\g?�J\oZA4�S�E'�4?L��*���Ҵ0�!�2�h����j�m ^LYL���i!�^��.�<�5Tf��J7�(�b�I5�ƙv�!� �:��pw?�z��*���u{���7y��y��ESgDg��Q�K�_#�}��7�2�]/f�vHy��/���}����7�ģ��D(�-�=,�ӶL�x3E�P��;B�Z����{��!?w�O���h�Rq�]S���&�1AI̕����}��8�p�������e���,�]'�/�b/��X1`�m䚓~MP"��d���-�Zp�i�RfC��JtR���0��"��
-:�b��kB���\\-�'@٬�*��i��i��$1�cˋF�./�]@CN�� 	A�}����seу�����^e(�K�0CbN������� ;d�B�I3+y����z�{�*��քP�h�i�T�%W�-ʔ�D�-�D�
-3��i�C1��f�v���WnzpId��;T%f�	��n"����=J:{�ٯs��xZU�OA�)/|4�tR�)�iZ\��#����Mۤ	��S\�E��EX��nN���0VL�<��ɔ
-Qc�/N,
-R@��鷐~�ЯN�K�7 {�D���������B)F�_h��h#�G7���f� �~[��%���0X&���YL�x!��rm��x�H"�+}
-k��t�2��6:�)/Vf�.�����q<�u+MmE2K���^%��F;e&W�>Z�ו6�.m�
-c���^g\�����T�6�xD�U��p#����+�m����nB�hfaP��o��1;U�U��.}�@��y�x*z\5��t��q��ɔ/�	���+.J���6��i��PT�+4�S�����G1DG	5�R �$��8�1�@��:���
-
-J����l;&b�i���� o
-ԅ��1f��{�(��?�EJ5Wщ0�H�O8�����#�42G�I�=��S��G�8ĻkC����[����Q��v���<��+���>�������N�Ea� V<z�\��V���"o�V�m3�a�f��mW�����Ą��旿mb���=�?���G���-�}v��V봗�=�YUY**�_�)4����5*�-
-�����R�P�dҦ�}�K�~��]	k	���'��,���D��|�ƞ,���2^�O��SMs5`F�=oQq0��?Z�1Z���0�iQ����5�n��/�9�CElwlm8�J����jx0@�"�*��3�:r�W^�.��>�g|�����RT�'ԋ�r���~���)��_�U�T�C��︫�]����=d�J�A��Gsu���̏�	�[Y��������X�E_{�d=E���`�_�\�0�4e�
-�C�,�����',˕0%,��(�铷V���l%�'�m���K�ք!��r��쳺���g�Uy�𱏯J�}��c�c8^�b�0��u��S���YM모��$����JG*�F�J���K�1Z
-߉g��3��4M�Zf�j��}��>��\V��M�p��/+5��
-a�OUn �"��*�L��h4���˪L�ӌ<��%��u�����Al�w�܋�Y�~hg�V轭�4fyr��e3Gl�#6C.j-O�R��^V]��+t�����6ɒHfW�WE|����RF��#��y>	^�_�N~�-+U�����o�ӱS^s=�LS�w�g�j�G?��m�O_��mn��;.� �|J&Tb�X��e8�ND�L�/�R��~`q:&���á�0U�Qr�f&i�4���~��0�g�׸��OݕNU���)٢9i��C�� �X���v��Jl���+�"��V⽰h��x7��V�vZXT�-���U���H.�W�r�����S��a���x"����S)��A*��r���9_�/��|&���^}(5O�/J���s�`����V����V�û�bx��Io�2��Ѓ~�J��gr�kc�����{�E���������a�>�߇������B����0z��'���s��5'����f{E��(��){�N,8���*kM�-ofQ(�5���+U�\#r��vQ�g����|�շx������i��%�sJ�74���y@�
-��G��
-wpx��x0��SŝV����c-|��S�㊥$}>Ul�VE7���S� �1�Tӳ�_�&���d�xZ L>���r{��̗z���K�mas[�������aO��p�Ք�nd���4��58-͛*#:S͏k����5o�USIJd���'v���=G�
-s-�P�ǳQ����װ#�2���?�ݮ�·��!JX���fE�N�
-좿isg��J
-��j��F �3��W�3,�.��κ��P�]?�z]��y�q}��-xl�V?D��'�Ó�,�?܅���b ^����mcA� ������q���n��؎�Π�1վ�Zo���:I\Vg2������l4���+���-�YZ�{L�C3���k6���.5|�P^�zߣ^��z3ȧ~1����%[D+D�*8G0�U�#���m-6�gGP߶��v��>T�����
-���,�#�nݩ�L
-�וvM*��f�+�9�R$w)����#Dh�~����������l/
-� 0%d�$��O� X��Ã��w����C;��O;�O���h|��Ƨ}�2������x'
-��w�0��#M۝��[4�����2�PXb�	%,�P�ˤ��NAj���a�LV����yGT�d@(�鸊i������]�I���Ru��_y͏éAOJ􏾏�MQr�>���d~B��$��9N����)cr�<M�y&ls�@FK�ϡK-�bj���1-d������޺36x�*���:����<������L�����_r5�P�x��������$��J�b\Qc]��ո"'ԇ%�s��)ո���R���I&�0�+��`�t��T��`qr��* �3��aA&k�_xb�í����#e^��Yt/N�U�-8e|qK�jZJ;@�2�:�۾q�TY�S��r]�۪��h���:^����Ka�%�������N�<��m��%>�Ù�=D�>葮ІZ��I�Oq�z�J�����j�����^�1���v��>w�v��ƟyZ�a��#j�Z/Q�ɅZ�C�Tb��Zz������ƿ���5r�qr�9�P�U�{h�,�S�n����%�ș��{q��S���
-�f�+�MVO�I�i�<l�
-E?K��Ja\��"(�t-�e~���O^*{2ք��U���x��֌�U��*��1�6�Ƅ*c� cm��=��Yḙ2��2��2^	���US���Bƺ2���1��x#d��2�Vo����IU��u!㭐1��x�ry�]U�jh����<���n�?1/'��X+>��F�ޣ2���Q"t�ɾ�}��@��_��Qh<_�=>����%�#4�e��6��=Jt�����#4�Wk���6�Y�e�Sw�L������X�K��KMCfkMj�Ӓ�xM��l��g$s8�<+�OԤ��9�~&{͑5�zs�<I�n1�ɣ�4}o	����dz�����g[�C�='�c)���񔰴̜����_ɜH@c$s����ɀ�B	s*Ō��i;����3E%�(PlήI��/3ہ�Ѭ���5�1�|��2_�,�_䔅�B6��)�Xd]�IK)n�d.�r����|4d����^�%�92W�ϫ��5�;��,��ϝ%���5y2d�L?�B�ZQ�+�s6d�J�j�V���d��U��
--�6G�ϒjs�,�6��rOER��z�9%<Mߗ}�3L�g�b>G�gI���X���l��Oq�%sJy>BK�8�{Y�?e�V�5b�,z@�z����I�t,2�h�������TsI�]T�9"Hm�#
-����q} '����M�n���(S����^{��' �q����>Ns�����v����n������S��{&]p2϶3_䈿ʮc��0��l��Z�L�'�K=k��
-�0?�DC��=`<月32%>j�\�!UjΣ�����E���؆2sA$;fm�3ó_Oh�OV�� G�>��GzT!�fZ��56U�30J��5���e 4]��~�D�i��q�ʦw��?�	f3:�4����6m��,i,���VI��j`��?��.2i ���Q4+X�0����'5d��=���6��v
-�ԍ�g�~g�+��7�_�&�;�]�����	��}W�u�8~]7����
-��7�߮����w����o�M�w��o���&��]����;p�]���;x���	��|W��q���~W�+���8~�n�O�+�>�q���~�}W�}r����	�>���;y����	��}W���q���~_���㏝���go��_~�?�
-�qWD��Z���P��6�\�V!�����̗",~���-/?챋�#_����ǵ��i�(H�e|Q�J,����3Nw4������?��9���4�ׯ@x����% ������Ǣ@���\�O��#5�P���q��n��IAc_��`��q�or2kk��W�
-�������z
-��H��E;'i�g�����}����;H���R��M�~,��[41Sg����f��L�|��%��| ���C&�Y�D�|���:4���W*�Uk�F�Tb��dihc{���(l�_���bV3ߊ�q^�k^�_�� ֑j-f��z�6�;Ӊ��aYk�VzH��<M�!�OX�]����x@CClkY��*��?�?T!��`U<�[�t����P�(8c�5�i�Ahl'kG�ϡ���m
- � � `�� �� � � �l8yN#J��,�X�K_�9��Dq2B����y P$�d�`MإG�tҦ}+"��W��5�$�QY��V�};"�drg
-�����Ɵ{�r(UR���s	M�DS2��J�`a\霖��������# j�o�A.kD�8*�>]<T����v����pn�C{�r�Ϡ�Z��awT5#�S����A��! �E &N��8]\��\T�j@��w͸P��6��}���$HG@&}+���D/�3��>/�s�,��.�l;�E�V�SMV"�K�ǳ��Q[�ݪ�`�	tH%���tV���Sn;U8�Z��'
-`P���;�X��$����n��?�������ث8��+��EA���KS��^D�Y! �j��/�q�mH����x᭨1Μ
-8����藚�ywQa�.�튴B����Nr[���A��콋u�5�TR}�����Ct��x�m�T�W�mc.�+���2��_l�Z�T��v�53��n�l�DwSD
-g� �9��~�-D�5Y�+_���!��J¬�6+Ns�<u�M��T|Bp$ �6�	<�ƫG�<�Y��=�?���c��b�s���ݪ�#�jJl��8��0��\�Aw7.;����kq?�Nt[��{��12i`r��7�W׸,iw�w���A��،`��a��0ͷ�h>�eM��Iy[�i>?�������C%3G�vX���!�"�
-;�e��|*�t��"��"�R��Ȫ���8�f�m�>���x�e�}�_��u��/]O�(�����i�ۈ�.����Ss<ND�O~�+�+5�Qӭ�]������.&+���:K�I����
-0�<��D,���l3�C�6 �썩z��#�!a��J�iM�:ܰ3��΅��Ky����|B��	E1��J5��q�9�Ѕ�jS��s��'��x�Gx������K���N|I5}�ؓ�I�
-�s��0��;&G�9�p�>�3m�WT�-������dd!�ۦ���C� Z�Qነ
-[B�O�?��5=�k�KM!b}o���Xq~^�Z,,*6��l��Ԕ��/2mC�%��-A�ѕ1>��a�*�JL�a{�n�\z���F�u�]!�kth��A����7���z�Mz��&ݛߤ�M*s��;T�8W�vѴ.W�~�Ms�r�莃���?�مI o[��[��4���h��*�S����}i�t�<~��=r;�c0�yׯp����jתU�)�6uWln��[���R��97Hipo��T����:�v��C��<��HkuGl~�-��˜�H�OH]����P�X��@��k*輌�ҷ��Ș1�"�4n]��A<L���~�"h�N�e4P"G%���M����e��.�{�@	p�e.+���h)�F�-�H7�f ����'�@��T�r �f e��xڝ�}�{���|�DQܳ�,��"��ج��t��v�mz�7�1�:6qc�%B���y���Z��ŭ�	yy_�����e��yp�0ܤ<�Wnr�k7%�u������۴<�7pz^�:���W�[\��<��n��W|r�]	�9D?*�#����o����<�k��\;�c�Pr��\�9G�c;�̥Xr�t��Dm^l\����|�Yû��[��#i
-�:�̗P�����R��%��ݘ���s��QA+P�&����;D1�:8.�B�D�J���;bH���{�N*����e�u㫂����*~C֯�zIG��P�fݑ���K� ���@�l�sPwQ�?��Jݑ��0/Q@�]}k�~U��m�ӽDmV���4Qx�_��+�R�Q��+��L����'�Q��wp;^��R��t�Rqxj��;��\x#r�w>�a?�2(t��3���̛�Bt(�j)����c�V�1.ܞJl����I>��G���=��%G�����y��ge�mU� �w\����/���-UƄ��|ؘ6&���acJؘ6����a�~ƌ���ʘ6f���acT��6愍�a�b�1/l�/��a�Ű1��X6���a��~ƒ��%6g��f�
-Y���?�����u׸׃{��1z'im��`��H���)�H�F�Θ���h���`:�ZP��0���v;�����}K�i��!~+�Y�Z�0��������4ʁc�)���c�����z\�{\�2�A:�L��:ػ�Ńs�ӓ��m��~�Ֆ
-��K����{.�q$2Lou�A�+�ȷB ���!ǥ���i�S�k��fӸ����Ԧ�_TK�9.,<��m��%K��1oX"�Oy�u��~�4}�������S�4o����c���̕���\�{��>0�ӄO��h��/�&�rqYĊ܈�'��ߞ���}~�<�&��̏uZTu�3⼄e�ΣǸ9��w��w8Ϊ�&Eߎxi��#�R��^Z��<��\Ȯ��j�a(�!��EZ���g��f�W��`�:��u�����V��mĿlY���-;r|�XI����6ٖ
-5$��
-U[�/׮	y���%
-bF5�Q�!"��W҉������G|B�$�#�.���r,���S,:�T �TߑG�׻Iu�:�y�.OrBJ�@��8R2��T:���pk��~x��u]۷��OԊ��%��� �Oy��AcB���`ˮ�1�_rW�ewИ�/�;ز'hL��l�4��K�
-��؁�-��dҤ�@��ޠ���o��$�@�:�?-����� �T�`)8��|r?��B<hڇ��M(�0�$�������@q�a%3zJ�q��-{=����v��_�3�Skjr �*�D� 'bTVC:�G�S����z'nZ@���VZ�V��
-v:������}���X%N�A��iwqŐ̧k���3�q%e>[�>���EI��#-�ء�c����ͱ��S7���.�_�?t���}W7��e�e��E�(�u�y�k�ֺ!j���u����	/���4m�*�ڈ�N��(։8%"NQ�~y8�Х����JtT';�[�����&��m�Aq;��;�[�UX�}�}-G��HE�HE�1J=V�<V�2V�c��X�e1߱��������������:����0}�N�n颯��dWu�^��[��[�r��V'V�L���k��k[��ה��ږ��5�69�֕w7}��N�n�F��j�ӰVgn�t^]O��1��Ax��ma��N��b�
-���r����1acC8:&�E��Zo��`s��d�f�R�UJB�`u���������]��w����D��7�>0�"��ϏD��t�O�.)y:�r&h��<��F��N�ax��P��V���G��z��v�y�]�}:�	��~K�6�l�x�_�l��\�x�_�\��|�X�/y�_���ӝf�e) i��ù����|���#z����e���v�K�8�v��cY������ŠǼ�&� u���a�v���9��m}�����p
-b�^j�C���1^➻�����E�uq���� K\�F\Ց�>y�����9��꺓��؇��SMk���~ ��sG�f��e|��-�P��~����������x�L%��>�����$�����w���3i��D����gj�WH���&%^�TJ{�yn��n��{�����҃qo��D�>�F����x�� u�eB�l�������S��u��C�����)�s]z0�8�}]�w�>�-���g�aBE������v��)�q�h�~6��Δ3� d�CA���u~��Jz�"�.m�_ ��%�[�
-�6Y�W���O%.��*������^�o��Kn����~f#+Y���ms_�
-oS�L3/&&�-�ċa�m�#O����ty�%���<���u��O-A���SS�o]�`���d�od����9���?�ų=�����P���ԙ��ȒgA��O	|�~�Z�V��Z��2i�V�<1ֿʼm�	r���Z���2^Z�������l�|� x�����n'�y=���6S�v�7��0�n1b)Z�Y��gi�>��}E�=�X�W���Zϰ6G��n-m�����~��-K\�8�IrE��~�{�&�y����VD���
- "���;�����V�8ZY�Z-�����"s؛
-�S�G��-pH����C�%���
-���bv毢���$�}y�7��볕�����7��������z�{[�-�r��%Z��az�7�L�aޛI�8Jf�&3CxIZ�=ӿ�&��D�{���"Ƙ�`�
-N�s����
-S�!b,��fՄ�<0���Ԭ���
-��S�&�tS®gnJ�g�b=߄�y�S���=������k�8�Ѓ���G���� qZ�����z7��(�r�ܜ�ə�9AI��N7������� %d6$P*;r\ρ���}�*�.20���nC�?�&ӂ+�rZ�/Uf0S]���di����Z1'�FP����I�?�Fuu�����/#�^Zh7B�x٢�w:�����s�$Wؖ�tÌ�:\"�~���54B�:��J�͉�iXi�l��ʋ?���"K�����0B���=& .��c�SB�$�&)!�ZJ!!��'�|�/sG���/`7�wS�Զ��L��L9m=���w��H��X(�u>,Dq~3���(��<���oT�4�6)lW�v��a<	� ���r����CSL˗�rJ׹�C��N���?f>6
-I��I����)c�Z|!U���H��"�o�/�d��CƟQ���}!~�����w�Sn= �jP���jh��7݋֋~ꮤ���2 J�Ќ��y>g���Y�u��x�0���x4I�|FG��ԽC�2��2Ք�ߖ�P���(�-�~����CTY���7�XQ�{��v��.9{����|���=0�Ѹ�Ƨ{3�S����2�
-u�oNz̋޴3�v�(W�^݄H�W��ѡP"1����
-��ȫP�RI���<��
-g�NU��CzP��Q� zI��h�#���
-�>#q��&�y�KE�-�Yh�,4v�h�c�W��A�: �a짷��!�a?GS�3̈�[`/�|@ѦH��)I��s���9"�s"2�9�4ϪC��=�GIn�v�Q�8M��Z�Y�em�io���A�3du�����T�/�#�@��S
-�uQ[�S�|
-
-zc2?H�����Z��-��Z�U���=�GŲB��V��Uo�γ�
-T�Mu��R�Gy�)��E�vyK�<1c;��iPsh��IkԚ�Z;���`/�������!)B!!FD�ެ��YW\S\�g�����i�<���Z={��ؔ0j�&ȦD���X�v��Gm�@�<�/4�
-�ݤ�l#~�OK���C��
-���t�t>��3O�D[�,���D���}Sӻ[a�*O�{�Z�������=w%��c�
-X��ƕ�k+q�Ub�U��Dn�N*tϺD�OɭhI���S��u������7Ѷ�z�5a>�2̽��}��}fֻ"뾄!���퇾�������M�g|�kW�(.��Q��/�`gO�x>����Dj��(��1��A�)D#�N�C��C���;��֧��q=to�b�;��R,�~�Pa]�J�/M��U°�͍��E���vн6л��s{�'�P~}"w�I�A���
-��ݵ������P�YqvpdP�u�;S
-���x�H���]"�/��^�� 
-4���6B�G�n��n�#��b��qsa���\~�f~.�-?���������&�`r���z}-T��<��˕��0��/�`�V�Z�l=,���5�p󽔶�Í#����Y�K����)q��@bq$�,À��S�=)vg�_���S�ﳸ7U�9,�eS �w�]׭��
-Z3�@���ma���`m+r�Z�}�\��UH�]�����o�NH³�8A�Y4{e�\\��A�ռn�o*
-e
-Z�f��	�A7h"�"p
-�쎄�ّ`� �g�Y#U�#���9�}�	e�RMr�}�7�
- w��٢��t�R\��V
-�$à�g^��h`�o
-��?�!ʼ�r�\�t��ķ*h{��
-ÕصO!"���ԛN���S��V� ��� F��A�ؔ�CO`��pM�ltt|U�E6B���HB�
-��Ѓ�C){��4��o�;-)��`T�պu�ȝ=���Ov���:��Q�ch�����\�-q��l��) 8���7���������=lt�����Y/��Vw�*�H��Z<���@�?Q������V�hM�~��|[)���z�"�	�X�" nd�J�s3O��F�hŷAu=��o�&�  ��7r+���;h�~��2@+S�/��gSF&�d>
-�<�$[eʀdmt�`��\�ӣ�F�C��m:�˶�yhL�Ճ6��H�6�X��m��Y�w���v���S������J-Wu����߁��Y��<�SՐM�e{0���zh��a5O������v���WC�TW�]�ᔠ�+�UUp#�D���,�
-�̡�$f5���]���\�H��ꌌ���(oV�ft�8_�}�MٿB3(���lG�.���:]"���[fz�`�ܕ�2�hZJݏ��l�o��\��z���5����y���A����F$�+�b;Ve��Y��f�k"l���\O���o%�Y�d?��h�����L�&_E�ۊ��tbu�~�E�YHX���X�bz���� 8��:j��\�Y��gC��#�Vvl�ֱ$?y�4=N� �x�
-.t�`?s���Mr�C���V4Ӈ�ƽ�0�qV�KQ�;��=W�;�MLw��rU�;#�y�|���T �_n��-�xb�jf��t�郂M
-���;[\��E�Z]n.�{`�Y��R�G����jy��:�V
-~Њ�p˴:��/K���S#Fz�d����z��n��[E�I�M�Ox�%���i�
-�^
-,�a��%���O� �j����z<ܪT;������4�j�g�/L�PbWm����c儉���m�=�Dys�a�[�۞ٛP�s��~z/,��r���Jf?-� �E�=�	��P���gǧ>K5�P���A�D��Z�I��)ѿ�ا2��(�����9�>�yl2���yq��>)c>�ң2Ɩ��}m"��ܦ��E0�����`it�T�S��uq:J����%��8R�+�!q�z'��ǫ^32EX����{V�n��w#K*��m�w =�m }I[ב.�s7c�ݎ^�6mkv�MjOg��2DsFXb�5tc`Έqo'�tn�
-�ڞ�4$��0���b����i.oW�@�
-D�Ej����؝���Y߂�Ӫ���-=�����m��ȥ�Nx_�#��bM��yJG=��;�K�@r�s�Z�v��BKi'�-��2|I���G�.�YioF��߱Ww<1�9�t<��V��g��='�҉D�ۉ����=�$:���a{qN*n���VR���T3`Q�̢b?-���v4�������W+�a� �����w�;"xY-[�=���d;����	o�r�)����r��Mn��������N����ir��7�ύ+�'�� 5wI�k_�e%�/(�s
-d�?�ۿ������O�
-�)g����R:BD	�/o+.hok��;�Q�}v�;t�S�a�	MH�Ǉ�[��B�Y|��^~���"�G�7� 	U�G�c�7Þ�7�Gݻy��h.�kCU��q���a�@z�|r�'2�'ף��'��|C�1��H>�@H�S�1��;�S�H�8�0���O��m�Jߩ}*=*>�.h��q��7��D��&��~f��sX4M��7��M���H��\z/��~"����~��D������釛KB,l��S���"���l���᮳�N?1
-�AV�$��z�_��^S�PM�$��`>7\c/�_W�Z���kl��b�e���r��`�_n�/��o���`\,�Ws%�(]����"ſ>�x��ϑP+��[�ju&�W�e*��~�2�m��r�\��8{e㌢}��F[#�Y�۳
-��ժ)�/8u/mw�I�;,g`�d�^�v̌�p���N�O
-"}R����o�x:F�������ϣ�a69��l/G�#��&��w�l��ND�z�#�	����@���|�YH�J��,�0��}Y2`v�J�j�s�#��:���}}Ϳ��oG__�����w���#�kT=�P���^���Z}}���V_}�B����$d�I�U
-�ނf���Gǫ���ytz�Ss@xt�9��9 x@� G"�C�A��� �u�6���qd"ZvnҘ�Z�ܤv�񮷍w��UלI��.��x������i��zZ��sq���U2O\}*�qV�����ɲn��å�w��m
��󭮭X]�f�7+3�*&Vմ~8X5m�&w�`w���%���(f&-�#�a`�C1�B,my�T���>nӘA�}� ��/(�[�����<	w"�Y�r��L�O6�h�H��l;�r��*4�&�bD�7?�#��dSUi�S�w>0��V9aR�ꭠ�[ �p����򽱀�Cl���&!���4��N^���E�Z���BV�E��z����[��Uϴ̫6;��:M�6��4����r���,*.|��C��^���5~�|2:���Z[��]��k�pϔ��w��c0�z��W��/" =`�.O��%a���kf�ݟ�����^�_HZ�Eo�9�;�Duv������D���8����8S���4BT+��3���&���R!����5&$�f߶�C���fٶ�C"n��b⬌�YvWm�yk9l��f���C8O���C�c�2���0W��&�W�(�\�3VZ��}$\��00�s����e�����[�^^��Đ��A.�i��r4��֠
-��:ٽJ������{�[���ZJ�±p�y��`�y���v�E���7�7� >Wo~|(�v�KS��~�o��y/�}C��T�wJ�����,n�4�mK)M[���ο"��*]����ze�UIv yU2;���ic���UIʃ�zӞ�Ո��� G��M)�K��b�׳";н �8��P�t��9���vI���ݰ=i'��� {�(�&�@g/;aX�w?�u/ۋ?��_�'=�I�ړ���ed�;�6r��z���z� @�ߵ���
-i�F��89
-)�7%��[�^T���OԈ<"�������+��
-�(�P� �B!zB�N!%��������L۰�mX����L����KE�$6wn��rq�&�v8�ߡ"IP�CR�CR�CR�CM�$���͂z
--�Sh���B��w���0��aR��F�I�A�A����&��3�8����!���EѾ��R��,~y�iЮ^Q3/yhB��(�����y�_�����f�`�ع�:&��Qo]X����P��xB��U~���MS���?R7�$��8z�:�f�ZŢ��#�H?�yrZ�V�Md6>W���e�ǗU���k��a�c�,��,&�� �����X�I��=[����Z�=0/�%�6�as�e#O�|�
-�S<���d��`D?�	��	�Ue���!K5�GN:&��I���p��^r'ݳ��(.1�L�=���ovП�^���r�Jf_H�y��"�_!��+j�1^U�^����*F��:�{wKv)���~�;�J�Rd�����W��R1K(t��%�U�
-
-�dM�s���e���������:�%�)�����|��|^H���S���LpB4!`�@�^�&�X��m,b.&&�t_6�S�A�ŏTs�2,�Aְ%ef��������:�߰��9h�aG��Feh�w��*"!�ܮ����S���?L����w->R��U�
-��}v���x��7�9�ϟ�h��J�{�b��}%v�L�^Q�=��ߕ��M��G�UQR��? �v��۠W$�6hJ�m�Z�?�1��C���?���`~{��Ϊ�6��֑�*A1r��nm�.H��M�D
-*p�� Z�N�� *������(4�3��W�'���H���H-�W��ݗh�L�!	9�!���諂e��p�8	'*R>�o�Ž��v�����#�
-Md�:�&OL�y
-V3+�
-goժ�[5�8-)�SO�U<1��� �����:Y�q<��SG�����ܣv_�)�<dgw��w�v(]�Uwi����?WQ��@h!��_ݎ�%�q������3�~e6��1��-�#G��Q�>U�;����]j��8>��h9�b��E�
-�ۨ�>�F���n��NiL�in�x4a�	�o���h�}_��o�Ʃ`��G��e�/�p}f=�OD�]������������nJF'8[�-���a�e �G�����>|L���T�dd���� �Y���&?n�p�>ɠ+��Oq�*g�Ӝ�ڙ�'��L|��8��~����N��t�3q3'����ʣ���������p8��!��6�nH�ܘLoo.ݘ��O�G�K�ɞ����ͥ�ɞE���ͥEɞ���כK7%{nN�w5�nN�,N��4�'{�$���KK�=K��ͥ�ɞ[��Cͥ[�=�&Ӈ�K�&{��#ͥ�d�`2}��4��{��s����H�{[J7b��e�ϙ�9�P2�Vsi(ٳ,�~���,�s[2�ns�6�p�������f���QÆh�}�Q����	�7���J��V����p]�SC���L��=���̬�j�E�\�>��A'W.B�ոr�V����v$mk��G���d䷵P�G`�[	l�ly+�=�}��{<��&�H����z<�Rg�W��Ȧ�e����_�'�7N�y��ab���	p<�xpO; � �q-�p�n0[�Z�����
-g��.�s*��`+0��`+0/8���Poq��׎�|Gs�o�%[��7�%ģtk�����Á��	:���;�!`�:0?0A��9Ya�vowt�Iذ��Ob�F`a$v8��H�� {`�8�ث0��5'�������3���	�9���b0��}��L�	z��>��c�po$E"�~��k �>�W[na�y���~G��G����|�`�:g�thLu�M���x�1�eV�O�3�ڡ*cyVz?=����1�o:��@�G�2L��Z�i|�v<�/��M@����&0�	ؓ {�	�$��q���:�V�����	`�N ����~�ۀ�����}�{ `�8��B>u$=���I� �s'�g�Г�g6�{`}1;W�l�UǾ��Y�������u<G_��br0_�7�CL�91G�>�d���z`��9�����6�	�<��p�mؕN�� �����v�� �k`[ v�l��;�^�uN�v}�!Q��DY�L|�op&�9�Fg������+�z!��j������b� ��k0�z��`ov�\͋c>��7�߭�;\p�s�U-u&�3��p�I��l�nu�n�
-��c�:�]����RZ���ؗ�ƹ"���WZ��%���RZ	īb��Wǰ}�����c���_���|M̱!_sl������_3w���]4���Ƕ��ț��70m�ũ���������RoMrꥀ��J]b�*"��Q�3w�#_������*t�=1��}1��:�����t'�W]�����.���Zd?�������]�{nO�?h.ݞ�#����t�gc���w��
-n�|%��͘�������փ�r]?�4�N�`f���h�ʸ�~-�x[.�x�+��G����'�;c�[��� 4����m�����9�l7/�br<|{b�7�{c�Z��񤍃���SZJqT��Y{�9k��꽾K���Ϸ����LgJeϪ %�3[4׬a�#�)��/�����op'�7�Fܧl"���S�FW�+Z1����@�U���=T�${�J�g���T�3g�D�J{s����+��w.�i�W��2��<�>��Df�*
-���(�(�65�M���������Til�$!�����B�4��M��]7��D�],3U?dDM�M&�$gL��������
-�jգp�� �jt4�A?,�����-����6���q*qx���c\?h�*۸a?4rω~h���X���>_Պ�%���aڴz}ߥ�ͪ K��
-��
-�y��F��N�}[�X�]j� e��r��y4{	;��f����1X���9�����O��0p��Ύ�4ҋ�v�����-�Um���c���k���߅+�����D��[���DM��@x���V,
-�[6%��*�kӹ�����PQ߯��{-uorM�M����eT�M6�>�U�
-���>��D�dY퇆k�3+��.��^�{��]�e#��QU�
-g��?�*y�Y���*y�˲��e$9�<`���2��<�߃즼ŷ�9�\|�~��]������7J���/��|@�q���~f�3h�[�/��kf �?�p�7�Q33
-�:C?��%=����H�Gӣ���
-�z���^o����^����7J��n�;�Ӂ��x{��P 6=��p�_�=|D��d�a�n���ϊO�_����t��2��sS#m�f4���R]�����^ݖ��M�.P2�L�#V�^=IOt]=I��:0��`�r��O %�у|�W�Y�F�n<6����A~��&3j��/fY+���h1���6����Ѓ�K	���7��nrn���2c��ˢ@���=�F;��$;O2MY(�����D�#��c�����=�u��={�
-�Sn��#[p
-Mr�~z�9%��cr�9l�f��5攘ȋ�<����L���יS���!�P���A3]?�kh[���%�7⢴m�׶�щ8�kN��D0_w��'�9�	�p*Nk9���������
-qڤ�(P-�/9m����i|h7��*�>f0����M���i������B���������)#8�ѧ��S3�Dui��
-��א4�����Ɍ��4Â��_��j���A�&3b� [m��mH铘����!i�,�P������WB�!�mh�eЬ*�@ھP�
-CL�'
-�#g�$����k����=�z0���6ĩ\�H�EC�i���R�}���hw�=���
-!�ԏ�eR�$�w�+Zc𗰕���Ⱥ�t!�I�S*�j����g�������Vx����y��{��Y�To�Rg�"�bu	���NS�މ*�7a�;+�P	�V%u?̹�/�D�I]�o�t:�
-v�Ӑ"�!�����D �=d�yYw�%wd��K?�� id�\��+[e�C��U�l���(lw�zC�5��u��Β�5�Z�>�ίi�7)F��{r����.^���nU����΂�������؛眂J�4����O8��%4�j+�M�������ȼ���,�8sD��qLF[�^6`��;�Fx[��oP�L��"NtPH�P�H�6\!����ߨ!k��rm��&6�V��'B�=-:��j��q�=:�i���4�����	��O���@���	݁��N�.�@Wo�����]Ё.j�������/�~���%���)4��$�i�E׉�j��S��8#�
-�1�Rz��LV���?��j�c����*��e�����ݞ�Fn�&a?�'�)w(?�����U�3 z�;���-��7���؍N��F�
-#��?� ��SbC�
-�(�
-��ž�l��qrqv��Y�F3R�����K#րN.^:�6�����7��y@w�z@w�P�����bBK�p��G�~��E�G_�ޒ�ٮ����qO�׷:bS���X�G:���h'_kh��m#Vi��l���۵~뚁!cP��pT�G�Z�RJ��(�sEyZ���1ǞV���P���a��B����'�9�>�g��z�k�rk�Ѝú�^W��U-�L:��������'l�����ڦ�*jlZ(�:��1��ڎ&4�FSpPB�aDU�z��s�"�Hz��}2�`\��^�s�O�i0h�j$����A^`kG��2�NU���8;�G����
-�LF6k�Dʸ�v�x�.�s���kg���=l�80J<��MV��s���Ƣ���̩��靜~q�gP���%��K8�>d�B\��Y+0��ПaɃ��Ǻ_!����U���9�Y�J,A��Y��g����U��<��Bu���&�c�n�\�9�,d���M.pmmr}Q�b&��'W�c*�� ����z\H49y[Z�D���������΂f�,�9b�����4��~��?~�/���Z	h������-9X���4���)��1lͲ�]k�a�Af�{Pȷ'��#�3�Ȭg�������U5��z��eL5�=�OI1��,�@D�ثW���s�U�Wb�ؒ��D��c�bo�a`J�A�S��).�f�t_�^��짣��R�1J�/���b�-�8l��PbV���l� 	C[�e�,���Omg�av��ש�}��CH?C��&-m�^�&J���պ��6��Y�؊�.밊J����]l��&�Ѿ�7��l�Ṇ$\�/�8x��|IdB=R��#���B̳��Q�ΣGj<zd����߂GQ�^�G�1<z�ƣG����<:,��q<zd"=ⶠ�5�G�"�y4h�Ѡ��ّ�<��h@�h_���ّS�h`�����8/,�y����q�*�p�p�����L�\���j�3�br1x��x����{���B�å�E]��.�V�K�x�F[5
-�,��^,��^(»^$�{�I��"�D�xp��?�+��PŢ>��jK_��}7|��#�p�r�.]e�!�sJ��ɦ������30��&�`7����_�l�3ӛ�����I���ӿ��7Q����9T�W`)�3�|'�d�5���z�fev�g���A�^4���A�	~bu�'JoS8Xz���J���p�=���ާ�Z��)}�����Z꼂u�-�Vgր-kЙ5����+<��oa^��`�i��6�����A��b������U�
-�����{��+#J�-����CS��+��|���	�e���c/�-��ʝ�c��/�W���];���/'}_qcu�0<EP�AgOkF�a�
-O�E����"���m���rq��/�J�6N,WELg��jC�"|�L��T#f9�y0�;�����rG
- �� V�q�txÞYq��C@O���?e�F�e{��8��^�,v̋#U��1|+a-����Y�dj;�=Me�xw<�o\!�)�m�+n7�⪩}Ӈ+8����Z�fU�_׋�J�u��Z|f�֔+�"x����h���\`��^'K,��X⩸�Zw�~�������yɜ�
-��/���i��H$��a;�?�=�׷��G�ms
->��O+#i��Ioj+Dk�R��h�B�?�z�z��+�Q��vD3�R��(����ۗ����p�`�3q�}^�W�py �	5|J1�zΛ[D���+��B���t�z��C�kqm���<�04��b,yd�==�Nڝ/���9q��9?W�_+?W*�v�\���au}&n�ϩ�z��i�l�
-�<����mUf��}�R���zГ�z�m9ڼ��v���>nw�S�af�/M���~`�%��G��y����4�3q����K"U�s֘����~���.G#���W���t�`+y;�h)��/�~P+xg���;|!tĞ/��4!G�ǭHB(D:�]!��X�t�{2�̊K��-����xh�Fdt�tC�H�H��H��`���EjX�s��x�j�7/���-p��PR ��%��	��ӽ�O�g��c�����Cʙm�i{���+_���ԭ�W	h!!A��&8�=�|O'i�c�Yy_�y��݊���Ϟ����7�"�̎�-lX��m�1 ^�w����$̾c�x�}�����B�d��~?ݪ:uj;u�Tթsp+�5IgtW%�Ts[7��B]��Ig�@y��L#��+>0r�)�s�rߜx���w[�Z��̳�o�h�n����Wv	���+)�dqާ�ƒ(�q\&b3��!#�Ag���
-�r�u�DAD,�=X.:�����"�Dt[��,c*$i�(Yȳ�\̎Bcv�*���TA��[Ke*��C�ZR�����Ħ�ZvJ�AE���Mu$p7�n�t�G�{,��oG�Vj�-�3NZ��L̄��31����/<M��i����^�p���dZ��k/6X�-%��`
-�in)���2�4��Po�"�SsA�g��R�.8(sK��&	��������6�����pr��ʒ��ơ4�bf)�mp��!	M��t�$�#�uV���/i��9���`�:�Qņ7���\V�^h!���!��.o��
-qQ?��.;���0�ʢ��"��$�s����	�X����1�J\/f��<���a���`�n�I��Y�!l�7d���+dR㈘�F�\���+�T�^_�d���Q�y��c{LM$��h޿#5<��i�'��8���xQ�����<����,38��ro>m���]�J���ځ�Vgޭ�F����g+���R�t�x/�8����dRs	���D$���c�ep$1�O�u�x����)'��d��9p�b��k�e�g��im��Jݠh��b�v�{�[���4bo/�!n����������2}��L��-n�N��j�s��7;��hZ?��]�@AW��}r�AV'�s.�����߈>U�s~��[��Y����6,�h��,�c�O1=>d?�����9�Z˕��Ma��#>@Ja��ԭF_"�a..�
-mLPZ�%Z�qx��
-ua�&������=��<TAZ����T���A:��T��Bq'/��c]ۭyq��'��x��!i	� E���OoO-!�}�iЧy�4�pHh�L�+S��B��V��jG˫�.�N�R�9��V���擅n�{�@�X�Τ�r�?k�<��'��~����|����I]����r�w�`���A�uD!�l�J+�J����`
-v4D�(�'�F?w�㍓��v�q���i��V��2pz��r=.;���x����#;|���@뜎�`<|�(�$mՁ����XG�P��9�D� j�(��(�5��=H��khk*�=�V��@��4&5�1єi��=>ezE OɕVWka��1F�i�V!��]�Y� ��םR����j����V�"��W�/�"�����s���
-��n�)�{]��l
-w�uu��~ؽ��ȭ��V�����Õ����V�
-u��[�Rs�����#
-���gR&Q�_T��U�!D#b]El]�I^I��7�]M:��U�E2�R���x������$<�v�� 8V8
-��Q�_E�f|��v~��9��&��&Qs�(ͱ�/J��J�U��^�Գ�J�.+���J�(�~��Cܤ`�A9n��N��R��$"Nٲe�!��9�4����PW���D�hZY?,���놥r��a�v7��Y�&$������wXw[���M�)�[�,LQ�.8�I r������^PT|�������x_�[�]n��b"��M0����8�		�m;��4��1�a>1;�T-�,w��+*:v�ITnq�/��,|X�ƾG�Xϻ�����}?0	�Ҍ�S$��*+�^~f�J�  �@,��A��š����-�do0��W昔�޳�&�z�jD�t�r�-ox�-����	�9��)!)�e�8Cb��� ��"�͡'�N@��P�e^����u���+�
-��fl<�c��$A�D��]E��E�-������jS�"{����nJ�/w�t3K�헉��io�ڝ�c�%jt����_�I�+}K�@ByI��]E�� �cU��J��G1b�,*岱� [<ީ�W_#޷��)�eaC%�m�����t���E����rBD,�`�(�Kl�G?_�����#�c�q8~��,���%&��_%�*�q�N�t(��h�'�A��2:����|'�2�����R=�
-=����"̴
-ʰѠ�M>��I�M~�3Y[a6d�D�����O��[aZ2������z��RE��\8�F�:Ī�h��/�I%�L: 92� Ȥ���H�'q�#���
-����` �uSQ�g�����։+��`��?x�*�C�9��d8I��d��d�¤{a��7!	2��&�WKV:+/�}2���h�ď��f紥C�O�X�,��M���L�"$m�����o<W
-&,KY�ϵ� B~�X���:��U'��a�0�0�Y��2?d����+�$D�pJ�.�C���\����f\J���"UX���n���Q�d��~�J,*�v����R47۵�ܵ���1������J#Z�J1� ����~-4�u}E`$+�p��,�	��,���dI;?��6k~���\(��e0�U�\���m��D;b+x2�gE��P�2��tg��of��F�:�Aa,�#���
-���|qnr�]XP�@�b��'ף�'��%���X�ҿ�
-������pB�T�y���o"�PxӅ�Qn���������e��|�M�$�}��|j�x��'�<{b�l�iM���o�+^%�0���a���^YJ��4"�P��|n�������s�$�0��]۰��jD.�<O������J�rrh�=�`6�a�0vu�;�����m����=o������R|R#�B�!����Ћ�zq�85�+��n����w����u�Wn�<�'|X�ut��ؽ\,{�1����9T���
-��Ԫ`cg0dIuWC���`�+��-�J0�r0r�:r�:1#_�������7������56A5A�R����ù�#�ϣ��c���n�U7��!9��y�8�Z@	�_��{��������խ*3B�B׍!TOHI2�q�ǵ>�F��;�f��T��챹�]�\I���	�<#Ds�����	�G�x�����!��!u|CGߑ��i嚻afȂ�i
-}�
--�ǋ�T}:���A���I��VP���}�}$�[��'���Kn婒j�Ij��M�
-�'�8eq�2�	@h�ix�Ï[���*����TU㏆���c!LQ
-���>p7|@��+n��>����$�^z"$Y��)���h���ZT!��P++�/~���e���\�HO+���b�[MUcDT1�ݪ��$�'��7�Cձ���_��ƕ�;�	�*>����ޅG^vT< ͢��Q}�Uz4$َK��${�t�'�o1.g�q1cZ9CCZ���T�HW)�|�[�C
-��s	�*;L`s�:>e����Q������N�=�#e�VP�VZ�g�~��z�-	��m�O�6��~�d�P���^���ub��xg01���j�_��C�:�k���t��i��*��U"���G �s�¨�b,�wT~���O��^*���|{dEut^H�񺿀R�F
-����52����iFs�a�yc�~Ve�G��u�Oܖ��a�eN�ck�0?${6_�22���;� $+τ@.Б���aʌ�Bh���b�=�
-�p�� '.a���ԡ�Q/�E;�O�$8������S�x(\90g�
-��Bd[�f����!��E^��`�Ӫx1�2�%w��ú@���i�Y�=u}��؇���5�	5�xK�lt�����B�
-w�e�o����!5����,df���>�'�5���I�I�\�kh�B��j�5l��*�Z�%�5����:��[�'�-
-e�㕃���D�m����W������M9L�ez�(G(��G\يB��Z���
-�IG�h�h\�c��U�7Op@5ݒ[q�%E���>�9��@��Kn�r"�8�_��P�dA�\0�o��=�/��d:J����&��<J��.2Jd��<J��.�l(q���s��9�������·,xy��R�S�$�G�����û��q���2�PZ�N��<T³ǹ<9�&G�>9DKy
-?ͬ��0f� Ø��D5H��V�I|\Lb`����ݱg��Qϖ��ϖ�h�A/|t�z��g�L��y��,�!n�G��a{F��ϳ�}X����ʵ����f��aD3o��y�q��q������<������]9�����y�D��P� ���.����c'{�K!��vq���O�y<V�-~�)V�4�~Ê�D��"�Sl��u����cc�.���J',{dn
-��l�aW0�i(n��|���l�m
-�6�
-�@q;|�S���V��*�sŸc�$�n�@I�|I]�_D ?Xk�$ɲQ�7O��+jqҝL{�U���(aS0���y��,�W=��`GӀ� (�ɢ�A�cR�ǼI��,���bD<w��w8F1aM��@�5K�� �u����j(3$�d���������l	Х>@���I����7�[�*p��JV$����,L��0DV_:�9�4��1W�%5|�o�z7iV8���v
-�6��g���'�؞`�p���,���=AK?�T��;��u
->#������[�؀�͉?85SqO�Z
-��]�z˓�|^Y�[U�GӔz�~��{����=�{�����}?檍즿����N�_;�ޣ�B�;�~oQ	���,��ZS�Ni�)�L�ͧ��F�'��)��.�@�����~�Q�����z���7��[�[G���Ky��o.ʢ��s�~'��1����2�6�F�=O�L'��ͧ����0�=C�M���E��w��W������vt}j��|�F���7�~O��)�ͳ��#���Z��h��^�#;jF$#;kF,�#�jFtȑ�kF,�#�kF�$G�Ԍ�$G�֌X.G�Ռ��H�&�,GԚ��V3�e9���B���R�tՌxQ�t�w��J��S3�M���)GՌX-�����[�����6O:~��8PJm爽H%Bq_M�������t×!���K��)�g�ʕШ����Xt��x�$��;R�Udr��E�vy��N�9E ��T����Y�y3wx��wo�h�]�8�Iż���
-���q�K�G���"�sD�dq��Y�,�҈}�3܈~Ã��Y'�Z�>�`��߯Q��N\�ij�c���ɢ�Y���ֈ��Pu:��$H羟�� 9Gz�(7|9����jJ��	��'�	�סV��|H+0o�$mLW�`���3&$V���Tu�t�'ۑ �%OBg&Y�*
-<�^�yt�G�n��C��f������!��U
-iZX*(�&�%�r�4=,�ʤIa��x��HX**��0�Ǳx����B�]����V{^*��k< H����z&�tz����[(��#�]�1�Rg�P��N�?�*QW��tYFˣ�hkt��U�h�\VOGy���7�m��Ǖz��1�^bm2v���d�����I�q���rL�w�\�N8&�ҡO�/T�8���>n����6�ڜ盃U|F�ts07��i�{q�=�Ya���&W�Vzb���9\�=���૞�l=�_��y�OҋM��p~A}b�G�;���>�䋜�I'�c���`9u��粇Vv>��������l��'$Ӿ�kO[���e�l�
-��6G�>��N,��N� ��.�����I��
-�yx�}͵��p#',	]���J�mP�1�		Xl�Ez�u=&Lb/"��U������P1.�G�X�js��n��|�2}*W�W91bxa�ѷ��w2�4��a�/$RW=8�/��#�J}n�!H,��1�w��)��ޜ�{ʕ�N��$��)��1���}k����8=B��LL3�3	�"V���®iZ�����^O��-�ab�s�z���yt�Tw�����Ĭ��|����nOoFa(������4��V�Aj�n��.��#�7	����N��xXS";-��?e���م4���I�4���o�<�u�/��6����i�W�wZt������W�j�st��4��������-e�������ΓS
-5�bZP�jAV�&���6@��֚�>�!hY9�*+��ʂp��'͑:xbA8랽G�\������N�p����B�Z|ca;Մ�L�?>�Q��6ӗ:�m8�L���F�o�ZƳK�Hk���=5ŋ� �)�l	O��d�s�')��l��̑$�M�
-}^
-��
-�.终��yә�^�?F��6gz�6��z�+��Zj.0�.��j�y�!~�'�r�|O"C[.+ؿ��:Ⱥ�{ˣ*$B�8�4ǔ�Ky�'��b�i�1�}&,)�aݖ:���p=j���n
-i���I�g3��tbV!�&���$qr�4���-�_
-Ҹ����,wǺ�Ď����f����p�p�M _!9�f�)R<����%d~�Yo4��~жDO8Ԣ�H4�����Bq�J�z@�ղ������}�R�֎Ǣԡ4�`m���V�M\3�)$��V7���p8ޭ�H5{������l�z=ȵ�=Fé��Ұh<܎ը���X\��mrz�0�;�؋3�\�,p��?���D/��d!|*%�t�DV:�|��
b�r��ܒ�u��'�=����9ٴ��ۄ+Iݸ���͗�m��벱�
-�۲r�[,׽����v�u/@���ۿ>'�;��xOq�(q'oe�G��pļ���Q���ʍ^4����`~��*�4�2o�S9rXc��k ��&��Q�-��*��Wye�*����X���.t����Q� ����{A��[�)���o�&n�ߢ��u�Lњ��XUE ���ɯ�0f���P��L.��4��9i�G�t����21y~"( n��<��I�'.��C7��f:{8�%��g>{��ۻ�W?{P1��J�������{�dxj-�I#�� �d"+U(%N@2�P��U.U��nkj���6!�~b1N3�M`�]DN��ӽɛ��|v�6���9u���X0���:�ð1q&�9��
-�#�"�f�8����c&4ۀ�x`; N� ��d` NѼp���
-��i5�8)�#[�i"*�&�����8��3��q�F�oŽ�f���Ĩ7p-�ɫqX�>���U"��\����hV���|s���o�F��y�
-_�4������f�h.�~�u�����Vl�=�����V�,�n8S��q����K�J�g�~�����W��0�wc��%a�z+zY�[x�j����Vr���vN�$�6��3sH�Đ��!��8I��t
-�	6eC�>>�U}n ��Ge���f�&���J��k������=���;]C��A����U*mU�«�Ū��D���rY���j�fނ�trS)n���9U�?h*����ذ�A$��/��q[����H���c���䆅U�b ���3�X�G����̷��Y-C��,���½2�h�P���&)-�lx��$wxELs#U�pEM�ruB��J�S�!�"8�@ɒdI�y����UF�]���6���oK��*W���{<�S���ǀ�y$cv�0��0�����;�ق���/��Q�庍r�3�ï���*�ӧ�mX�w�M��;n����w�"�!���3��>���D�����/8HS$�Ce��K���6��ve��߽�u��}(�
-�q�)�+�\X�-�k������l�{�����H����=4w�S{�i�{⻼��u�r|��O">t)�|���&���!;Qfå*Z)�P�d���8kYG�{i��j!VcI:b�ELt���_��WUG6YBrd3�;Q��,#'+4��z@Hmo��-y8Ґ�2��me]L�����^�:aO��C��7��}���YãE*�Nm.G��Kԩ�h)q
-��C��W�(q�k�k�D��˃���!�` mO�[C��Ѵ/u$����C����Lç���0�U�7^s�1R�2 v�L_#���|`aѡb0�������_�+7
-��ʪʴrī[@�F�*,b;6��)���e�P<�U>-����&t���U�kc����a���WM|Z�n8�ł>���L�?c�3s������	�gYԳ�A}̄�sF�h��~P3��<���r����W�p� ��v�R?���h0��wG�B�j\�Ei�+���'V��r�8�Vt��5�]n��jt����x"F���'!��|�s���5ћ���7����P����~�+\�
-_��-����;^Q۽���5ն�بm[?#w�4r_���ɍܙ~�=c����d?�ϚP_e�O�P���Y�Y�s�A}ڄ��~:��t?�O�P_ˢ���Sס��C}�ԧ�E��ԗL�{�3<�?ԥ~P_�ی��i��5:�JA.��ŵ�S���⚋Q�B.
-8������)EqD5���Z�����Sև����z��~����ke)�Y�v���A�<=�H��Ao@7�p�����\�����\�0�/�P8Jۘ%�LWl|c?��r܆�Oڨ��NN�Fۆ���cN��Q?�uˋ�V���P��nu�g>�n���N�44砗�Qqu�/�����t�'���;�Ƴ�a'Q�t�ˆ�^�j��EZb��"�0I��%���>_�tu������]����֥��z���\l�<Ŧ."vY�l�͟��/��,-�����rQwZ顱�{��8_��x���q��6�z�`�~�� ����%tAv	=d�~�Iңz���01��5P,�j"������h�$�,4�M�~IZ5�h�hiX~h����1_xm'Z֨�`��i��uZ�['�	�ܱ�3vN)N,q��3�8�6�Xb�i������{�ϊ+](u��8O\YW�9�a@X�]���������B�'�q ��O�Y]ns��ۥ4�Ɲxʧ��4n�W	��Z�u�㾣's��<��a֊�,��?���������y6y��qMv��H��{G��J�����F�y�7<�U�� Y�V�p�L��L�D�����ho؟�sa��p�dT���d�p��p��/�p�U�����>E��\�S\���]�;��wR��!���O��i�)����&��ؔ&L��0�Tt1Q{��=qʂ¹�!#�ѲD�u3�|1K�'@?��㖤��N;�j�:�Fz�2�C�4�Tݥk�w�v� �x�g���|O�~o�RèR�T�O��ޥ�Y�9T�-�?�|��Ǘ����`��`]�<�֕����w �Aݏi�B��w+q���Xy����W��Łr�\N\�W�Ï���ą`��B�����AS
-��Y�Ax��%E��A���5ɇ�CD�_�6���K��l�:�.uuX�J
-������7��M���+,]�K��o�ep��!�VI�T�b`Zi��Y<4���	���z�>�
-���?�� �|��M<�W�X��_���Va�ث�GY��DK�|�����"q���f�١9_����1ԟB}���	>cQ�}�U�]AZ���է���|1�x(���Q�P�S�1_ԋ��k��:_��_x���ݳڰ�Q�r��_�6�
-��UPi�h����m�@\�?�C��s�,I|IbMWa;��OJ}2��0C�_�@G���t����nS����t ��>�c�;������ |���?��=��������W����/#����U�3��[p��������eoD��M�G�VP�Ď�CR�hX&P���0)�,�r��U^Y��|���r���ɘ�ߚr&-�9�����p�Nsٮ [7g����C���C(�o:�\E�f{�����b�B1�d�M������C�����#9�_�Q���*$�I*r�E�D.�U�<�9��@�*��^�S9�^��6Ћ�� ��Y��`��݈S�U��{ȇA��'Q����~?�s94-@󮩜�Fs ��	�a \��*�{^��x�h<)�gj����-�H��>0E\Eć<Y~��W|.�10S>�<�i���`{=v�Ϻ��X��S�]C��ޡ���`I������j�I^�eSʧ\���_(ڞǗ�� ��)9��Y^)�煾�ul+:�K�X!P����LF�^�AM�W5�������D�]h������t�6HNצ.y
-R��!���e�F�pU�8����ke+6��� R8P�[�1��WZS�����&.2�T͙9L�Q�Y�~��~t������
-�e�᳊U��*�� ��U8ظ��g��&�^4�f|At�,�R��\'Q�'�)@�����V�j�
-/�V!<ж�C[�I�Ip/����&.�	��O�Z�����*�~�{"�O�؈tt�O5Bnѥ����j�t8z:,5vɴw%��t����+q����J����b��G����w��G�8�o��6���
-+�P��L��'�6Ȑǭ�؂���5d+͒N(m㨋Mt��yт(���'�v�\�
-�y�w�ӑW-ذƏ)�
-�#���b���/�"�����|� �����~Wc7��E���x�BE耫�
--�w\�����h��$7k$4�ٻؘ��:�f�"<*�<ϏE
-i�
-�Y��2�O�)V
-�CE2��9���z�td�@8mp�� K�e�=�~����<"������Zm�uC[��r�m-���*-r�2�z�RIH��T5iK�6Q�a�V�y�9$5[a�.��i���Q@>% ��9׀<	�y�2��/�����&�Qٽ��ݷ7�$zER_	dIt{�v�8�d&3�,/i^2JfƎg�&�W3�~����L2/ߓ1���l^�̎w����H��b/xc�~��޾-	왼�����gZ��N��NU�:u�[[����R�f��&ɔS�;A�H`q0ِ�y�����Ķrx��]dU���[+=(�}CؔǴ��p�>Ɗm���-NbT��V�j��}�B�� �b��2z�藧֏WS��}�s6x�x�of���mIؠ,���/L�R}�*2g��8Eb�0C��J�u��˚Z�^n�`�W�j���.n�b�k�Iqw��g���
-��oР	����:��sn��\h�gLF��2?����ԏ�܃��ox����o��^[ϋ���@���_j�T<Y_�fO�q1;����ۯ-+ႎR���"|aW!�:�@���6�Ͷ.V����_�}~��=�F��-/�n
-�(p^n�'{��jx��@���<��J	˗-O��$t>�B>�kE�!j�|ԨW�{�<�75���U�z���`�` s�p����a�q��y>�Nw ����	.�!��~Y>Gqu�T���ց
-�i/	nT� ��1���Kɧ<V�vJ����7�ԉ�p3��
-<���������a�4�/�yBj������?�	����A��������b���ǊTIZ��k��ґ�)z���}���CZ ��oJ�w'|N͸s�	�|����\��nM-��^(&���j}�~��	���0�O����.v��i�q^s/}we�Q(��)�
-��r.��"���-��|��yyY�ۜ��;�G��Ɖ���Z�*�����
-�rhK!�Z�D<[�����P�!B9�9ъ��P��;[�(lh���F�g
-E�hٙ#�b����O6)Dv��}:���\ҪU�2�ʄ�:W-�4iO�)��:@��G/�NQ2�fPpS�:�I�f3��'1��ɠ�Ob���.~����I�63��'1Oyd��Ob���>�IL?����ݧ���W>9^��������+ן�<u�R<Qy�d� ����W篟���ɩĳB4�E�e�~�JF���01�pF��O����;p2�ef���$��J��-�l���$��>q�TW57��m��u�Җ��:�S�GI1�3M��!K!�:��o@����)��Y��00�!D�:L�K/D9��[���1�q̴�UIs~� � B�
-�B
-
-�ISY�U��.G��"(���^6uw�TD!�1$_��5a�8Hr�B�B����r�4a���Y3��P�A<Zߏ�x��6/O�/
-wט��fGvFb{sČqA��h~��*C"Sk#a8���&�:D_���!�4o�D����T��D�0�XrgGrW�%��;�)W��R�2C�X���)ˋM��N�?��6e�N|��염��th�����T��O,�g�U���PJ͊+���Jg���dkP�Ŋ��b����1?怕�W��^�6�4���WI��K�+�#��J^)wU<{U<}2VJ�6�Y�]��ͯ�V6����qaI_���3������"����j���au:�ܺ^�Pq� ���'���+�-bA*f�-�|��!�J�_���_�Қ%C�kc�g0��ԷT*�m���y�Bav�Esҩ��.���(yߘdIN��g˿��I�R���h�����&�˩��v���$�b{D@��GeR�g15'���+�A�̹q��h=�*=bo����q����,���&�L*���@� �j��(w{ႇf�6�Gʵ="�e�pjr�8w.(��h��z�!s6�?���TN}�$�Z�ק�Kv���>��)�r�𔕀���\�3�g�?!��g
-qŶ��_���v�����E���U*�=��8����e؇
-f��wU�4�>6�T*s���̩���ݼ
-�h� ̞2���c�2BF=��M�J@c��`��ɲ'���s�kb��ܟ(�~X�}]���X����X����\���Teǩ
-�EczŨO2p8���|��Ʈ]�+�ƿ.�u�y������S���U���-��!� af"��z���
-&��c��P���V����ڠ��k&��T����"������W
-D��3�K���V��1�z޾�2�ҹ��S��
-X)���!?l�K�(ТRb��\�V]���$�K1���q̦>�;�[)�u2|�!��9s��!偉�W�A�|�I�;t �j�`�AB{|��5��+aho�h�4���4�{Yp���b\k��\�=[	��Jx��/	GQ�9ڗ5�?
-�x'Pj�L�S�Xx6kb��یg������o���,����!tm�+��y"q��\��O8K j!����!%��8u����O�����N��I�4:�Wu�t�qm�r8z@T������4a:�
-I��P���Nb%��
-}!��Ѥ���q(\�F�QO��H�)��rR�1����ެ�A�B�߬�(c6@��Iuxy<�ba��W�.W8f�9��u2�\S���s�E���	L��@�`����:R�ŜӸ?�ˀM���ܠ&�ao5�R)�H�VJ�܋����(O�Du���xV��9\`�X~�������b�U4�l
-�|���4d�jw�x8�1������Kns3��GJsԖ6|�F�2OF�݉����:�[�5�':QD0(���O��D(:������������ڱ�*��"j��j��5H���,\<��)O�sr�����������������uSÖ�������F�߉S�D����~3��eq�e+1�Ne1者��wM���wM���w
-��P�(ʃq%�)ŕ�>eG\iR��q�YSvŕ�^��X@y�I�X��|ΆJ5�傣�Ф1<�2f
-���YO	
-���
-��� �@�<�?��3�u���d'k�1J7�QF8�2��Ѕ�@���o��j����&�2�y{Q�69���uK
-1V}t��'���R�cd'�%�M͡�Yz�_��!«�u�b5\�A:�����w���?T�}8��C�k���5}�	m�������.�������u,0|��]���2a�2�E�����-���6�Wq�D^>�hO�/<�zJ��9Gū3ȴ�f�K�+�^|Tqì$Uܓ�|����*F< ���َ�(�a�����w�4�m���O�١b)�^����l���LeH��_妰�,��
-�V�=#�8{�V�}�]K�u�:T`[)��w��'5S� a�[��w���gԛ�PF�� ��f�� 6���h`BIX4�g�%�w�M��!i�Yh*�.�2s*��w�8�� -5�E���޹AyUA~cL试*j��a->�?�Xe��'�]T�b	��G���m�6
-��z��d�/C���.��F��ꠑ�R�h+B�
-�"������m	O!aX�Pn�v4"��7����^m�U�KH�e��^�Ae��Q�Yz�4���LDW�k�4�^m�=�KdM�1��ۆ�M
-�Y��鯇۶B�a�|���{�?�1ƫ�1T/�D�c{8�'#���#c�Պm����jFvӀ�wb���ƙN��l�q���&';Ln�͈����u�f���Jez����k�����u_���ٟ���:�&��Gt�u�&/u�&���2���l��S�y���Ң�����5�`�\�D�_���*���J�~L��W�8�v��/�%z	��op������p��d*����3qZ&ԥ��8���v��_Rmӳ�L��&��
-�"�/�m0g+�����g-��o�'�Qi'���Գ��ʒ���]n�N��>��*��V�qOQ]N�m���n�(�C�q��Ӹ���~Vk4�+�o(7��W�7
-�{7��������T*�w?�\r�r�'��?���g���U��+�|�Bip�,����½��n�E
-}���B����~K(����s��O�"��e�pHr�K�M���#8�b	Ξ ﷔2:�qv��j=y](�>e��,4�g�����*��f�*�Ey��Um�?�7[���Rs~�>e������է\�'�5��[j�j!|I"�F���(Is
-�}��WrAV�ﰐ��H�T���. )�*���j�v{��k���Fy_��C�w����^ XkC0P�`��`�p�0�}@���t븡�t�x �~�j~�Gk�f�[s��-�%���R�/1����:'����p�T��^�E�.��b톗a�g�"���w9�P��n�T`�n3vT��u)���@["�ܡx��w�
-�Z|:��J.CG��x� �����`2P[�����B�)��BKԞA>Z�I9\M�η�Ӄ�*V.ti�������v9J�!���[��D��#����n�o�����D@U�x�����P!sA�}�>����SN1���V	�y�6&|a]�y�v^�����]�L���n�$.�ϫ�y���G�!�_�k�i���k���I��`���ϿG��j9o�~[���U���Pk��I�������h�ۡ�',V���\�P�諐{5���U��G#�ަ�R ����� �L�|�Gԁ쩱�i�3� H�����K�-��G$�p$w��o�H��-~���
-�
-˝����(f��i�
-���Bn{��%|t�שh{�)���-���
-}���h$�-�T�
-Wǳ�U��'{8��(XRL��J�^�x�9�YSW��Ce�C�ӡG��b>��z�i���,e_���eu̎�������/�or����+�E�$����  �}b)���W^bj������C��C2���/�k�ڬQƚPN)���_�平VmW-��U[YS�����H�7��⸣��N��}1p�(AY��9ݽ��o<-���_�,�אE.��1��5��l^
-Sg�Z��G�����Q��|n&�|�:��	���C��M����M:/�=?bJ:���7Sӛ�tc8{c�:�\��>n-�n6O[V��QcOX���e��Q��갱f5����K�g��R���n��nO�.���'r&w:��J���������vx��Um�4q��P"�?4壐��y�:.q�?B�K'q�>M��xF{���=��s��Sn�N�C�2�IE�!W��+����p�v�]�.�����r��-��
-��!�H��wqY�:y�#�*\H���ŕ��0�3��[�Y�풲ʿ7���`d}]��Eлl�ڴm���ڦ-h��*�V \i�
-�U�� �l��*�] �e� WU���6��0�
-p �� ���*�� ��p/ ����y6�� 0���C��
-���U.�|�1�|R竅�մ�iЁÜ&C�B_�ͯG2.)Z�*Z��:���G�y�7�ua�Ë� =��I�Da�D�7=����QES[pK��ZЏ�츷s'%��ti�Q�{Qȭ�m�L��xuX1ہ�e�5�Z܄�o:�F�)Dö>lV����q[u�r,�:�]���j��Tz���WEE0$����
-�7���6&����'?��)��o�-\��2>9�3yUg��΋�N�R���� �l�.}�w�f��@/`ؖ���<.}.V����Hw������\)^UŪ��Q�a)�~8\*fO��QR�RW�84�u!?���<	�x%a�`��|��*[�:��g5gM
-ĖX:ī���2�#lz��ѯS�k�#� u�'R�a�ږ�.��[���+y�8�Wҷ4�_�S�7�-���V�+��Kw����uR�(�ѓ9�V��tX)�r�^����N�0��)�|.��������)kJ��Prv'{d̬��:i�X�D�4�|.�>���~���G+�����jjU��zّ�j�
-�!`^�!� ��� ����
-�`x��F�\�������H�aDK��`�]����i=��o�h�ay�+O] ����-_�]�8ZB�yc1u2,��?�+��WˋBɚ�+jr���T}��u�_S��~�:̯��ug��A^o�Ud�s����a��$|�^v���Lʽ��L���)���b���a�̙�����b�j�j��L�S5��S�P�>	�A%��%�S+`|��6�����Sj�,r�Ӡ����s{ ���-�U̬��^h�w��-Ƕ�q�/�Ax� ��R���N�U
-�( !g���2pf�/�Յp:Iy*aZ��1�o�����#��a`y�׬�T�CV@��٨n	�@��bj���6��C�"$@X�lz4�w�)E8�zA�c�iH
-��e�
-�R*��K1d�Z��bf�������t�����G؂M0lN�l
-(�����ʬ
-u�S�Q��К��CP���:��ػ�q!��usqe׎�fs��7q�j�x��\�ч4vˢU��hk�Y�}��50g�u�ٱ�	+켔�H�����bM{Pq�èOu�����5uL�L�
-ʀ�.,���إ��� M����r��͛���܋w@��S��a!`07�[���X��u$�
-^0כ��%��{.�=7m����h7;��>�	��ƋN�vlG��8�#���I�0�����#�m��lh��n��^�r�w��Ȟ?������Ɗ`�K��75���Z�4���h� ���m��F��`�(��T�ꕪ�S��g'���ʢ�E92��`޷�� �Ґ�K���<�QEe�H��0�pvT�&&��dy���!\��e	Ưf��t��F�?��m`	�p�����C�ZG@\2��JZ\.��/���ХL�V44�Die�uM�E�H[���+�%��JK�q
-���"m��`D�s$p���`���<@|��D��{�'#O�����?mQ)r<�#�<������p��Q�)�v~�/)s���%
-:V�;�mY9]E4�#*�#zc����	�Pn7�f/��pELU����M�A
-5/��D
-���@�����+cU�݌����C3������#�.%N+�1�)斚�g)�V+�-bX��_�̕	BR��uN1w�9��L8{�L`^|Е����.�f�G��c�O��Ԑ5�����d��"�e�Á�����N�Td�]Evu��]/�a׳8�z��Dg�c ���<�����am�um�W���K��܌D�/ѥF:X-ry�~�El���A��G#�3��J�:i�/����]C19���Y�b��$��E�Tk�\S��o�Jr\�tN̒��P��Ơ�����������tb�&@3K+wRt��H�M�����R���~��]�9�{+��u��3�^s�q��a��c#�~�[��{�����ӄ���Cj(�R]��)#�l�b���X
-��� �_�,�	���s��(%�:�[s�]���� �'��{�-�ym���eh%O
-Y:�'��ح1��峚=m�Ȍ]�A������=���~T��-���6Rw\])�?�����<�/��5h6op�7�}Ct�~�|K�w�#�e1g��}�܃��~#����O: �"�_���߰��Д_�B�t"5	��ԋ/Il��s�8���a"�)��"�g��gzO� �z��yX��1y���G��>�Lu&}x����L^�^?���&�gdv����J�p��{Ib��2�]Y�:*\>/���s���-8L+j)t�s�$0�vEL�
- Ӫ_#1:�2��L�3j�$F���.��= ���/Й�+��'��z�1qOD)������M�Y]��#�b)u/�|�	���qG��m���g��q��r���^������$ob�P"hr����R0e�܍ழ��Zq�!���u�8]����m�[���5�� "�p�|f�z��^Zf�q�:H�	����̫���*҉���-�%ZL��w8���r�}p��kh��{���{/,9�%�jx'�]�V4� ��G9G$���Ct�+{�_�,wK��������J|f���h�1Vc�bS�R[y���1(�4�&柈����[L�N!���<O"϶�<O�y��Ā�w�[��G 1�-��-!TM��m�őt��a��I/�0��l w�L���b���g#�>��g!���(�;�Ʀ��4� iD4� ш�ö7��(F�?��C1�a
-(v�L{�ee��<��;G+l�l����(�7b��3umVH|O��U�ն'b�2���K�T�Bo&V5��T�Ƽ��1Ӽ���0�O�����36��"(X���iF�"Gko��,��g���]��A��03�EPz�r���YӖ�4�z�YM�U�7�� ����z<�@o�:�$������e:��B�Ѷ�^�Qco��^����_Ax�ޏ�P5|��-�k��KZ0Fht^�2uZ��s�����[C�J�34T?�Kk�^��p5
-�b�헖�����Ee��RGƀ��S�u����ǅ#�wq|#��}M�ymA��kJW"�+%;�MDÒ�^ӄYz�n�*��.�LINoT�]�C��X�j���p�_�q[��p��r�QL���SV�ʙ�t.�/�̼(������@A+$�	H��$���=�x4�[����Q�$̛[ż�;[������|+�D�܁/�բ�BH%���4a4��7�ψ��˖�|�8y��"yJ���DzE�4yE#0�֓s��e����U��ϕQ~�H�����"\,�֕��(d��9��'�#���<s��j�Z�����#���-g�Ĺ<*�Q`$��cr,依�E����т�寊�Y��X�^u\��5��ͿP<<�����x:ž1a���7&`h���H] o�� 9�"���������L�D��~���.eM�3��gF�|_����ޜ@'��h�%*�͸G�B��|KykM��s/vr���_�^���5Q�
-��n�zm��]�|��>��<Mle��x�L˨�9K1�K����e1Ņ,�ڐ�ԫҶ;j��U�=}���ޟ�{��h�G��[mх��R�수=#b�510�Z݃Wa^�W��0� ��ie470�j���}}M�5���&j�6�D]���5Q�k�n]Q�o���6�.������`�VF�ai�#d~��7E��rGT�����cΌ�����H�"����Z�H�;�-9��Ő����DG�o&w�5�J�Ud���C̻E��E�!y.j��Q<��=����l�kт�k8b���g�G�Q�"��m�H��q�Ш��S�ȱ���#����}��V"�g쑃�������(�h�`�y0+�ʻtSdv�n�̊��K�W�k�~�mj��ՅRXP���G�:œ˵��_7_�S7�Ϣt�����E�� Z��.�2�7x!7-�J,'��[����R��p��e���&��ZJuU�	��xOlAq=j�.��p���Գ6
-�#�îpW��yc�֤�L*g�ي"�o��PފyV��bXe���8a|�إ�Ob{���^aQ[+������B�&Z3}�\ja;p.eK	����Ѹ9���ь��'��*�#��Jw/��� �]�F<K鏎v}L���K�
-�#�c&ao���O�o��{��_F�T}9��Q�$/0V[?ѵ:����AV6W��hP�b�[���bꕄҥn�W�[����*��Nd.Z��}�y���U�����j:W-��,����Մ"ճ�[`�3}���]q.���ޟP��Ѱ�N^��H�i>B��}l�h��H;�o�4ŕ{��;�^/�d:��n.�)
-�:���X�L!�v��=J�̭� ��9T(���: �|C�#a��t���Pà�c�6\V3����ZM��O�r�g��ɩڣ�i�c0yuPα�4ǮSӇd� ���]aڼ��:e��՞_�O�C��V�}�*}B��_�OYMZ~�>e
-3S{���˺��݅����SOt?ò��sW�Y`)���3�,�K���%�8[	���V�Y���U�D-3��f���GP��V�hBf����ޢ�(E=h�V�������V(��/X�CV	Ք0�l%<��|�vX%�ڇa��J؁���;�0����{����d��Y�����;�lxw�t��xw[xw����gû�o�CB��W�b�gBQ�5��g�£V����֪���X��<V�eq�c���X��<^�ei���rc��8�
-����p�ʬ��OE����{��x��C[9�@5�J[�U���9�Us�q��@�d��!jE���;�A���wf������wV*�/W*�Je^�����Lm.re���}���A1\�*�}�2���@�����qjf��abP�%
-���ٳ�y`
-8�����pI���e���в/w2��2�QΩ[Z}t��w9Q}�����֜'��u���<bK�M�S��-y
-t�Ӣ�_�<@�ot 0���>ȿ�T��wk�v�{����M�B���%7��4Bש���0���щ��h��"2�d?��I&2�0"�sV0U��jLk���0��g��7�c��*���ޓQ�� ���'��^ �m��oy��KrD2����_�۔V�8�ĿoՓ�|����mzr�/�
-�^�Ƴ���ް���2n-cBf|X��m����\�gy�������f�J�'�S��lxXq�����Z�Æ�|lC�ϗ	̚T�Cx���=8"���E!��Ǖ�A�|�����'\Õ-GaJao���Г{�A	Z֡�𮎯�N���F"�LPL!�|T8_�W!�n��D�Z�>U�e��Vy	]�틖�_=^aT&���x��9�V���������)�M��*�|�:����A%!u�:��IR�'-��=�wz��N
-ĘYZ!~�4�O�L-��
-"\�*�����Ŧ�������s���ew9y Ǝ�L��G_-vIqk��r��1�����"���k�ku
-:�la�]YI�`���>�L
-��M�6p�p��.u����B3���"�=LKq���˾$񉦵2(ZE�ú*��~L�lz��7K�K��_�(�J
-�*�Z�xy/���˱���;�֊L�ñIq
-�
-W?:���"�H9�	�����R�ԎЮ8x�K��q�6�^�@(����4�R��4n�U
-�tVT�c64������VD9��6�|�Bhe{W^Q�6>X��q>���k<4,.N���&_�(�oZ��Y�x�3�7�L5I@��)�;�+����1%'iNɉ��Q�n��@�������
-XH��Q�_�>�
-���gA/#�hG������V��-�3
-���KdR�-d��&�׫��=ɤ��dk�L���L�� �����&���dr��dݿ�L�Sѯ�G��J&����)g�L�� Ԝ�{�ɛ �7m2٧��L�̉
-?��;in�IsY���J�V�o��߭�߫�wT�;�����]U��*}O�}�����OM������jk#"/������H�T��\[���/��ƅ����A���g��w��
-]�Э�ؤ`e&� MX�[�x�b��|�(�e_l�*��	�i㱍�Z\X���>���G��ɱ��N��As�/^���ޖ�Pz�lB�jm��(����6uX�$���ck|!Tj�^J�j�YM���!�g�Ho��*���+�e��:�vSVQd4Oߗ҆��5wh#�@�qS�H���&��j.;2������|f���h��;�xl�����P�gV�����:%j"��5�(�),uE��o��G�Co��Ѷ�
-Yޠ�ѽ��݀���G����X�n�Z��D����v@K�f�ɻs0��65��V|^��ʣ.6�;�Y�(���nv���kHc�n
-�|H�z
-DRR�*1@j"
-g���Λݘ����[�@t�Á��2���S���J��D��I�gW�E�^���
-Py.4s�Y��d`Es�z�7�h������S���̣H��sq�����ߎdM����	�������\��
-�9��W|��D�5`�x#y�G�&�Y�Kn�[��[�}E�i��Iq�����9Y���FBo��#����j�"�Q,vX?V |B��߰�쮁�MZV7�鸋�EC�-��-��T֤�.�&q[t$��l���?�J����p$)����!߂NS܋$�޵�m�kAc���;�n�����$��KK�5g� ��Y�k-fGkX"<_Z�!�0_��ϗ$
-Y@!����3��U��B�5I��N���--���D�N&�,�b��v�'��g[������!�h�|	�����a,ݿ�T?Xe	��X W�9����C� �&��)S#0��]@�(v�.H�&l>!+a�1��J�W�K�@"�-�$Gvyi�$�&WW�+0�ы�)A�`�
-͡���;��1����jaפa��A�O^���ъ�V��ñF���%T�`G�3��åO����� $1�{ZpTg��jYm�D[K(9X���>[�����;T��^IE%�"
-/�� �4u��|�"����d���/���%ն+���o��ۑ�wx;�
-FOIB��䄰sA����UYYd�o.����b��HY�Ζ%\Ԋ�u��+B[TI����OJB��nN?���W��?t�]|m�6s�܆
-jNOP���+�'�Y7װ�lfn0>`�8��������n�>w���o�����=�6�c��:E��z.�DTp��SA�^�	�~{���������o1���9H_�~
-��g�>䧏�{�zG���o��zg���_��Դ���j�'7o�����n��͝>ډ��c?������1���f;�
-˧D�U��}`(Q�M�=4�����x�v����i�+���Iy��S:�S�&ry�	Js�!:��Zn��I�
-�q}��5��A��QW�i��Zjc�
-��/�C���q�,��TI�U���Sv�]����K�{��;��`�O�&W�R�H#�ЊӮҴKn��/I�������Е�ʄV��I�ǫ��äv�Jq�L�z�3�i�3�iw��.N�X�K�al��Ű�E��������%X���7����1�%l����<�g��	�K�C~�P��&h��z>��bu��,݂h��vڧp&�
-�Y�?��O'���19Bl?<�`-5] ���j�Ҙj����9e�]�{gN�(�f�:���(��D��,���Ex��	"���sq�6�o� ��C�"s�IO7R&5y�p8���e��T�c��Q��a���X����ʺ�ܳqӺ��
-�A�b�*����ѦP?�)���k�b<�P�=��#����/(�Rr8ͥ��La-���Z,c99��r�h'G�ٮ+��s�b�$�_������J1V+u��j�X��=d�Q�����͗�e�.f��k���1�*�+J�i���*u���*�kJ�o���u��o���
-
-
-
-
-Z���AB��A*�eA*��T ˃T�A*�A��� ��cU� ���'�NS�j�r�8U3�f?BQ��^�	G頟_T#x�7����Pg�dn*�U��K�2���|B����黪�I�P��*yM����`����N2g�����<���R��qNs"B/�}p�\RSr�W�[��@n��B~��2�{����o�a��<�K;�d��2��3%��r�<��\�}��+j������X'¬�.���|��9ܚRx
-,�
-��q�/Q}2/2΃��D<v��-Z��\�?ߦR�^����vr|͂u�GC�.T�i*Gp�5���اR�x���R�Y��1#]��<����	�SJq����/Y��'�A���0�,/�#us�a'z���A���aj�Pv�FHcFtx��.%dm��y�g՟�}y�TI�ء�&rR�
-ˏ�_F}N�lˍ֐w:��V����nv�v��G�"s�7f3���:�Y�HH�����+UBc%��y����t��4�
-
-�B�#������QPԅqB�DB傄�.N"��Nj�dC��J^�.�p��'>A�V�L���g�����x���U>�O����f"o-���׬�V`�4�|�K�YN�l���D����Y!ѧ�\�Q��}CEO��a}��hnsə��<A+����X%�С�=���ǥ���Que�D\=�Eԕ�-ᔤ�j ���}�8�ul ��$;�
-I�/}���uA+%�sꗾ�a���)�z^|3�yq<��̧0_N�����DS"6�k��
-f���� ���n��m��Pd;%���]��5�������}!7�r���Mg��J�b�hc�v6v�q>Ff�#��%H� r��S
-zSA��z�����HbW�YT�t�6d*ք�u3cr��Gݫ��� �b\S��k�q]�7
-�_�o-���q��ʼW߁[�!Q���2�w���T���t��eY���4���g�G��'�%�8_�F
-Y�ap��0ڲa��
-����XA�;���܌����e��p3�oK7�t9U����T�I՝imE��%3���%6�ۂ�s�9[��F.���m��[z&�Ή��P�'(�9ސ�͖5)�nP
-�K����d���4�
-�se��+���<_���D;��<�h^�Dۃ��A�In�(s/���w��P�;i��&�.�ϖ���M��Erm��`���; Z
-� ��s�</9���_��6��)��n���;=�*�!���E8U�}�.���Pop�Y�茞�f�ٶfg��l3�Jw#�������%�:E(:a	��fˉ�Q8�͑��p�u��&	���[Qr�w�̬.�)�fe1�H����Ag�&{��5�5��2Ԋ��s��f�~2��h�g7X�:�]�}}7�u��N;W������G�%���hɛ�ă٤`����0�ɑ�#��4�N����2("I�) L�E�������F�����,���<�º�a%zV�7aQ@��
-�ܪK�Faɞ�po��a'{�X� ���=�oN�j�\�6��7eo+��Vӕd�p���.��^�{�3O�)Y��J�K����vM:��ڳ�����t�>��.�!e���ԙ��iC��~�L"V�����̵��/�	c~��[�H�=�bs&�
-^�
-Jn��1���h^��]�F�UPX4C�#ؽ\NQ��d�*4������N��Dn�w%�o"���M�� '+�t`�VI����&�����o �h��y�K�t��.�v,}�BN�Y��b Pf�օ'�,�B�J�`.��,=�`�!�7i��U.y�΃
-�;'9'YZ7$!�v�	z! ��L&̪ƅ��E�¢J�GVEDFQ�V�����j��z��ww��%�Rfꀽ����aU��)f�_:��g%1��J�Rg%	�hq�i��i�
-`i�#�-j��|`�3��i��1ЇB�w��].=��b]�y���2hY� �0h�� �o��0h���p�������k1	�g�cr�}�0~,��-��f,�?,%��u����Ɣ?V��q0 ��9@h�Ja����"�SN;�����w����5��{����.H0�?�"�{�B����w��L�ay���a)�Q0�H�+�*��4f�~�Z|E��}4���X���DU �d\ P���B�O��3 �d� ɹK$�N��L[<��-~(�{�;RA^p˒C �w ;_�%����!s��-2{�$h��+��cbvٞt�=ۺLϷ���
-dU��!v2D�0��àC�N�q �1Tt0�p�
->:ܒ�3���q
-:��A���8t�K��AG���$�(�:�E^�񠣸��i��o�q"��O?'��"ɱ�6�9���P����� H�4|�XI���
-Kn���7��B�7�5��5����*}|�/��>-��`(�� ?��r�ָY9�.ѲLC�
-H xS�����)�J�j��z0l�9�Oi�	6����
-��c��D$I�΢;�
-9<�w#�8������{*��B���9���k��D��3I:�,\�-��l�E	�&�+�ɤv\w��%)n$u���F�����d�$��1�BDDݑSA4|�R���>3.s�P@�݉��e����ƃ��s���*�d�ٽF�3 �l@���a�4�"�S~�ԯ�*S+��
-�ڏ~Wʡ���J�W	�*ٺ�Y-Ci>a:�~������N�$X~�p(�L�A5�˕Sbuw{\��F�\�/�D�`�z? [��M��p)]�?��E"����ds��!�A��b;�7��wv�� -���	r�x���x�q���*n4� ܫ�^#��t�&�e ��k2Z*�*��vD{J�
-�瘲L:����NN�";m{i��Г�v�)���։�B��D
-9Vq����Gw�(["�G�����C�U��\"�L�5\��H����l�b���i��
-�g�2f1��j=Jh/��X�Vf�I�-�h�dN`�W��
-7I�%�K�?��5�#M߯�k�M?��4���������������������~J�Ok�M?���4�����4�sM���4�����W��o7'��d���$*IsRYZ����<�M%j�T��G�j*W˧��*[+�ҵ"*_+&�~��֟�м��VB�h���VF�h��0�|��&V�m��6�0�n�����OS	C-@8j��Vy_�9Y5���U�i}��k���:�_R��W�o���v�S��q7���1��[
-1Tx��������U5͑_�zb��%��y�\�,���BH�i��:�>cj�j���g|
-�4|0�����#�g}z
-8s\�E�����M�چٿ��%i��,�"��:Lgx�����Q�|5%��s�<5%�ӟ�jJ:7%-�biY���_�����=��{Aw�s��k�l����/펚C� D�E���Q�3��gжW����ܶV�U\>��g��������}�G�.9�9ӡ���BsҡN;t��*D{�v�%�c��a)���(�M�ݙX�M��!�L��t#a^���V-�A�QmZ ���#<��z�����i.��|V�ˀz�~>����Ϣ��
-�<�H�a9�^ M���'	�敲��1����$%3��x�4w
-��WKI{[��u�_bcT�>���xbH��쐣.���'{�H<�'($������r"�sP�J��7����s\2�L�V
-�Xᤪ��Cił��H���ʏ��'ك���sM{33���7�A�A��D�x��L�),��u^B��zK�Y"�9����`�p�r�t�ϻ��{�P��j��S������Ѝ �[C�*��eyP��թPN%6�Ӹp�7L��O��ֈ�|zV8����C�pʹ��5�����{�>�0��o�z�#�X5ZT� Ң���mU�6�ڰ>Y������X�6���a�J�Z2��L
-��-���]�͓ ��N$���R!D{T�4�L+�Y�π�j�U	��M�$W\n�*E�;;���m�>�u/1����E�i�(�!���a9!��J��%�~;�"#ӌ�܌�s��Ud���Fn���P1��Q1��i��Jv8�CB&�%
-�O��1��j�S���3���0� �c��Jh5�'�O˒�u������4��������EDn:��U,B��S_wmG���<A��19-o��<�������اr�N�Ϩ6��p\��J�D���|5�]���Khձ+w-U�F7���Ԙ�d;�z:�9�Qe���)����S�:'�'P�k�O�yoa������_$�t+��������ɩR�j;�ʥ)6�t?+ǚ�Ő�+��i�w �;��;�슌�C��C�bE>�+�����Y8�Y�En7o����ܖ'�Xs�����Y��Z�4��-������ِ�*��z*a�������Y|���T@���lNRƓ8d9e�%Pn+�P�h�f"S�2?N�㠏g+p��5�!`qEZ��誅�a+���8S��8;ةŴV��+&ޑ%� ���l?/˧$�Q�x�����GF��4���H3��ÿ�գ��#��a��+x�2Ꮂo��gh|t��G~��>����|��ݣ�����C�W�����G�bǃ�p<��cчz��\�P��G>8��c>x�С?��O~t��������ȿ}�#l��������5�~%�w���?���t����0����U�~ߒ�/F=��o7�������%�_�.��_<�7��}�+��|��G�>�xߝ������v
\ No newline at end of file
diff --git skin/adminhtml/default/default/media/uploaderSingle.swf skin/adminhtml/default/default/media/uploaderSingle.swf
deleted file mode 100644
index 3dd31ce..0000000
--- skin/adminhtml/default/default/media/uploaderSingle.swf
+++ /dev/null
@@ -1,942 +0,0 @@
-CWS�� xڤ|	`E�wWWw���$��� �Cq�]�]�@B�IP��0IfȬ�cg&{"�'�^ "�x��x x+J9����>�~��{�����/�{U��z��UU�Ӕ)���J����(����)�c��1ե��s��-�1�ihS"�6f��ٳg��}����̑ǝx�#G�9z��Hql|nK"8�ؖ��CO����
-��M���I��A0:���;��ұ�x���~c����c2l��$��w��Q����g�9� ��몏�(JM�E����]��m
-}���1�4UQ�ڌA�UȜ4>�m,=�C��6��b�V��U��i��J��VO���=O�VbUd��m�����5m��9���[��=6˪�[�c
-HӸ�k��}<-�
-j�`�*=�9�c�6N�:�O�^i�hh�4$ڃQ�sr�HJ��o��gH�
-<C!����0,��6�և05�#G�u�4�F6��6�b-�����H�Q��D�Q�T��H\n�R�"ql�8Ʈ��u�ʷ����e.�qiQF�\4f�M�b&պ�h��W��8k��v곖�'m=��Θ��.iv�32hb;��9P��s�m�i8�*���2���G�� �u��uR�
-�zU���G}�I3��ui��|=9u�*,`
-hVF�]�T�9u-��G�[�	ي�̠wP����Z���Z�%��{��m��Q�I��K-�����K�����V�8ּ[j�W�C�g9�g��J�tz�?;�\NTx��_�����w��v�X�:_�Ly���5����3(�3g�܎����P^�0�9
-zc�$����
-��+��DFA)��7����-J�_FL��P�#�!6CF'��R���\������e�_j��7��rr�����N�&�����q�% �f��&e�.�+��U�����k���}X*ꋎ
-&��+�&s�pRpnk{�6ض�x�SQsz�my��Tc�R�__�ud�g�e26$��>�9�nH��G
-GL#�>g��UV��F�ϯ�E]cd&6s�r̺&�@�ܶ���u0'"3[B�.Ǔ��I;0ee�Hs����h����� Q�kXNVݬP,�[*+����iڑ�W���8�Oi�KK\�ZȖm�;����{�q��H%���Li�Ir"-
-:�u�OE2%1
-*��j,��f!m-3�l������$]�s�5�!��K��Kd�\��vڣ��ع��i�h{(��h��HQ�b�͹.�@���,y+c����5;Қ�/}L{�@z��>X=�D͹�2CT2ݰa��%�$7���|����CE&]�r�a�IXM�PKC(����'�[:g�H�lDA�]����4N^��O*��b�t0�n��+)�a��e��;(7z��~%���������
-����c�{�B�Ͷoڜy���Yz�SMK�t�F�ړ�.4�h�����G��r��7� ؽ�E�kZ�"t���$�Sj�nh��%�~37Uh�3��¹�@9��)K��]����)&)�S����ël�=������ŨӺO�t�c����Am_�9�<i�����<����m9��笴�<^���*�>�0���ݸ��:�i-�;�a�v%;"��ߍ�J��xh*��ʺ�+Jk'�UT��PV�\2-��][6��nrI�x��2�
-��&?m�O�^��d�K3Gئ��ƞny��J��.�l�T*F$N6gnYzZa���������ѥm4%�'P�j�K�`s�Ƅ' �rǒ,? �*�ſ���z��i?������`�[rMS
-w`Z�1��0��qۏ8Ӻ��p��HZ~3�d�ַ�H�l����h���8�XRj�Q��$u��B.�c�%��Pv�q��+�b��IU�LU�r<R�Ǧ�Z�3d�wc,8�jl��ʭ���x�t�*�9��޵�%�8�9�KЍ��,��'e�f<��H�G�!���&�.�sbvJ;�t��!�4����q�h��3�e�x��Y����|�s�ie�5U��ߌ8���F�ʮ(�TVW;���fBդ�,���-�>�d��6�D���9���9��]$-B�~ܤ�q���TM.;}BYuYv��95�-g7�QPZ5u,J�*���;����y���֔ՕV�^�J�wN�_�L7�괲���V,�.`��:%��g_�%��[iY6)�,W&;�)�&S��`k(Z��CO���yJ}��CI��֥�|�"�t�s��h�J����7�^���ֶ���ݖ�Ǣ�Q����m!�d	����PRo��'���^��p�Ywg"����jj[�u�
-������[��M�8�k5�F1&���(
-H�s�xHI���5���'za�5'���K$�~�+)-��R]6�������%iW|^J1�j�Ie�e��C�Ie��U�.�/�N���uR�I�#2���nJIuYem]���i�ҩ��q�U�g�U��:���v`r���>ٹH�O�e9�R�{�ff���Hm$G�bqt����S�˫�M��9��d|Y5}'QN/R���L���WR%��|n�M�3��Skk����ol	V�)eg�`�Ԕ����)��ShB��qJ*ǗՕU����P��赙5�%յ�-�~�����r�\uYf�|
-+&�֥	unKȺfJ��C�S]��R�l���!�eY�H}�#�YҀ%]RzFA��R����c����9I���ش]����a��n+$�š�d3��d��B�ՔM*g-9�8nFC�@k�5���[i��䒏'���9�R��R�S�`Z�W�����0����ʚ���N���G��V�
-�B�z+�|V�=�NK�>g����k�&��m�IUo�[J[�}_�K1֥{�*�\Q�Wg��Id����L�D+fRUunF�Nf2���[��Fw]$^��k�����+�j9S��Yp�b;g,�g.��Ln���A_��2�O�.x'EZ���4?Vy��I���H�]�?
-m��:�bJIi݂�M���@���j+*K�؞� 5�� �=�rO��ѿ���m�o~o�'�f�ˑ=�s��K�@���.G�����<:wT[7�
-ze��71���	�oV���Zf&��_L���*�9��b��FV�Ekk�7iq̴F��9�[;����޸W~�m�{f�I\����
-E�:�����;u�q9��;e��b�p�Kw�/,���d0�J�>:����$�n<V���JN+s�.�2�7��1�5`Ra���N��imwкl��.>噯*�F�����\���!���cj/w ���X
-{G�cψ̌�b�ef�N�v|ƻ瘌(�ڣ�	��b�֛�K�և·�q�CT���!��9�C�e�V�Z_�9C����Hʝ��U$
-����t��M��\�a�jrí��Z�ks
-�ΉIo�ةc�N�!�nʄ��2��4������4�9#�mo����&�nl��F�脔^��>61���ٍ'�;�.y8���:�Q#=i7^�_~��a&c�p���N�:�|�œ����]���fM����������ƾ�0�����9�6Xw�o�H'<�5s5]Ak���&��㋷�Og䈓��J�)n�t��}C>�M��3rzh?�!��N�������
-S/��c8��O�0I1jx1��^�ȷ�x�#KW�۲��Ŷg�|q�7��F�������K�|�q78�J\�?�
-���妎!k��UG�2�R����e^a��蚉�zFH�+*b6���V��rL_�wt�����jy����,#>k�Yg��QY2�b���#��_8�X�"�b��Zĉ�eW��]��VW�1�/�dv�:b$1b�a�m�
-�_D0�m���&a�i9mi�d{X_|Y��x'�MhqspnqkKtnq}�8�j��yq����8zT��ǋ!���Af��5Vl�H
-�������5�5�x:�wj���_�~QhZ�Æ����h��A.���	u�ۤb�t�hpU8��I�-��>����
-�toL���$�64�lN[^dJSkKY�?ꬿ4�e��c�֛I��w��P�m޺��B��z�1��-���2�X@U�!�yg�{f�ؿ�%>��d=�����T��9�ly�Pǌq;�mI�թ�Fv�:�,����6='��Z[���
-[_jh
-Q#+��%��'_���zp����p4h`&��Ⱦ�|�^4z��3(����$�s��V*h鶹S"sB�8]�D��
-X�V`�
-�������,\0������*uMq���^����jV�Pu]�^��J��*��^��A
-?�lS���;(�Z�&�类j�j�G�I-<����s�y�uw]�]�qĬ ���c��	^������-b}�?�_�y��X���i��Z�
-�%X�`9���#W�y���@�>B��~�&Xaf��
-v�p�!�=T��g�ЇϱB�l��'ܣ��x���p�Vd�N�ߋ�1������9I�'�g��_���x� |�7Q�N�I�7Y�*��J�O�j��Z�*��	���?M���3��,s43�Ts�*�E�l��"�zh�F�@Xf�@�DD�"p�DE�YZD�U�D�o"z�Lp�;K����E��;W��]��C��S��K��[��G��c"�\`>� 8X�\ \\\\,K�K�z�{�ˁ+�+���2`9�*f�U��&�W2Qp
-ᯁo�o���PDL���O���/H~��5�� ����;*D�V�?�*�&�&��D�U䟧�>竢��P5χ"(�HE���nQ��Ū8�Rd���p��{%ܥp��]�*�+஄{5�k�^�:�׫��j�l��8���k���n �g����Xl n6���w www�����b��c��o���z���
-<��b���GT1�QUd?�q�	�IU�O�}xx�	<<�:P�c��w�*��
-�*��:��x�����w Ls	���\�i.�4���~� �>@�������O������\�}����������	��8��ة���;W���] �<����½��p/���b�K�^
-�2��W��&*�W+41�j��Z�:�zM�4�Wk�56(lf뀛�_�26�܍�m��]�&��>`p?�x xx���
-xxx�w�@��&*���`n�>MTaLً���
-�����  � �_ _� �? ?� i�u�;�8��X,.� �ˁ�������j`
-��C�Æpm����<
-<<i�`�`��S�O��4��,�x�-�\q�J�4M��4̕��D|
-����_ __������? ???� 
-��;Qm�����ej�y��t����GT��^�|�l���
-�K̼�搬~~s���w�,�=U5�WU�}K������$̓U�G5�_������s�aY���7��K8B�>>�>>>� ��B�Z�����~ ~��D���E�/H5�}.� ���B�|�Pa_�2��U܋��X�5�]��`�D�ȵ b#׹�G��ǹگ�|m~���Wd~��O�C5�\�����.���[��nv��!ݗԯ�o n6����<v<www����=���}.�~���,�f�j��Ƞt�k������1���tWU�|��4�e���b�b*3=�3)��T2��($+QYY��Y>I��y)Z�aw6��QF�U:SMˣ�(೚�hv-��NJ�۟�H�B�˳�eYP�~tD�z�n��j�ʳ쒨�*��o1���>F�)�_=J��6Yp��~�P���q�7�y���a���gلJ�-g4yn�RH�S�RՂ$M�cY4��gvU;K�v���Mߞ3����C c�R�Xx�)��4Ev���рܴ��z\̋�@�;���6�SX�[ʗ&ێ��߈y��$ۭ�?�{m�6�I�@���*�߯��,��+9V��D�G��Q�*�-�$�&��Y�e$נT��=�c�=�_�����m4yjdd��?�x�ǘGq	�����1L
-���Ԃ�=��_�$��
-2g�L�C������i�C�#m�<�i�LJѱi��҆x��"�Q�Ap,M��#-uNҠQ��2����HO���z�Z��A�%����yA��M���>��
-8�䠍eʸ�]��:^U��\Q�*�7\�~�*�	L1~��{��L1�`������L���)Y9�y��$U�̔����[<�?�)�L�SƔ�r��ϔ�	L闫�b�)��;IU��*œ�2�RU��R�#��2h��>UU�T���j�U�*Gתʰ��r�i�2�tU9v���8�)#�dʨ��r�_�2z:S�?�)��c�og0� S~W�ii���	��򇐪�1�*
-s夙�rr�����+%U�ʸ��J�_�Rv����Õ�QU��JE��Ll��)-�2�UU&��JeW���*S�ƕSc�R�JM\Uj�\��P��\9�]U��s�Y�r�,��5[U�2�+����s�R7WUf��J��R�w�4��)��dJ�_L	��)3��*M��#��u>S�s�3�D��|H�BD���v����&^�N���Z��5Sf_B���YD���
-,!�����Qs��L��љ�JP/�K�,c�rF��U��+���p�f�5��z�%�r�,�zF��J�Ռ��
-� ��!�9����m�K�G�W���נ;�7���oAc߁>ξ}�� �$��)����g�g�/�ϲ��;�<���\���|�]l�J�xh'[����f�4���f��a��e���c�@_d�A_bK@_f����.}�]���uv%�l)�~��M��-v��l�;l%��j�7\#���{�:��zľ�V��[
-�"���r�M��\�e����ۜ�;���]�*�{�5J����o�����~�������c��8�.�8��8~ �s�>���/���_�@���~�?��
-���{�9����2��?*�5�e�I�L�_�5�!��˵���
-�N�q���[tc��-��\�QWi߃��~ ]��z���5�Ϡ�j��^��^��1e�v.�jm>�
-Tc
-zF۠q�Y�bqc#X;��`=��ju�6���nk�v;�Ҍ;���� �S�S��tX]�]`ukw[�M`��mk���b�����j�Z���ڧ�֋�b��~�^���em��z �W��zU{�����ڱC�	ʛ�j��Xoi#�j������
-֠b�TE�J����{��X?�V_CC_P_���n�
-���ܚ*�Y�Cq���Л��~h��u��� ߥ̛�;P�7�w"�v�9������_@
-|7ZP����y|�n���T��5��������%j�:{GS>ԔoRy~В��2*�Q{��I��B��g9X�'�\,������#���e8�B�ᬿQ՘���5����j����)��*��4�ݩ�w�س_e���~��e�g}���4%{g�#�sg����.�l1\�"�^�
-,F��(����
-o��zէ�2�3}ְ���/���byg��:�W�^e*65��cԌ/�Al��/u(:e��J����_�U_�o�~5�8�jƚ�A�װ���AqW��Q�����9�
-Dx5��(sU����U</kR3�!�:�5l^`wg@���t�@�Z�t�R6+@CN��i��r���\�$EHR�ZUP|W �.���
-�g�\)�����3%���i�����ۘ���Y��cf���b�Q-�V�N�����D��j������cT'1n��A�wR��3
-��\�1�(�Y�a�
-b���9㠞��p�>�����{����L�R�}}���tg�u�xj���\�;�DA���~T���樂�X��]P��3�!�j9L)M������
-�g��
-�C����nf4C�JWw�V�W��t��3����c{����&�uA��n{�eC'0��گ�3�
-=}x�����{vl^6�������vh�d�ScH=��R�s�����"eS�q��&��kZ��T쪴�D��̢��ņ=v���){#Z	��2�f<�I�i%#�m9��-���r��� �)_�v���1��Y�V�%�<c�ڥ�Q�� �����ϸ�P�G��PT�r��Ӱ�}��h8^i�W�b,�IV��㱖a��c	�J�v�N�zo�H_���8�g�K)!$K��W�uA��nH�^KJW�3�d�v�~��X�<2g�\�ۓ���r�=�0�aUhX�����'��)g �T�b-�*ģV/O�̬��T(�63vYLLr�Q��~
-�\�;E`���N`A*`�'@�f	��Im�m��l�sR�������Z�ev�E�����X���V)j�(%��x��%�
-)8��O�/��\�7�-�|�mRu�V����t�W���vm��*���	�a�u0k:p*�A�H�N*<���5Ey�����Q���L'��]��?���u��ЕY%�)wp�Xe�0�C�b�&���a{P���]�T>w���_�$wK���ޒP}��˿��6�6!�x�]��doN��=ɹGr�%� K���ܫ�~T�/OR�1U�=u�C�Ww�q�2Ͻ�L��4@}����Q�Q���^�������z�<�u���7Pt]�F�2�=;����w<؅��0Uw{.�=H��x/U���2���$��*�:���9^z�����(��@�趛��g,�h�b�������Y>An�C& ��fj��T��������;$��~��4;�A���2��Fda���������d�/��U�7ʲB��%�o3ʯ2X�Dh������y���P�>���|�j��!Y&$k�2��A2q�@�H��T�Y����ՠk�
-�YJ�rh��lM����>0���e`\�b��46���Ȥ�t����I� �2��
-����{dO����Orf9�k�3
-�k��@?y�=��lz?�댉��}�~N���3{��sOWg����z�����F��O/���%G"��Ԭa~�6[�f!�C|!�3�nFR{�����}�alD�N�=n�2����h0��ݝ���BX*7��v���e3V�7�����eo�F�k�e�ʨ��^�
-�J�7�k���q�2�q��MOC���,���'��S��w�o������Ns���&,�<k�����_M����}Y������r�M�Np��t.�UP���:�}V�̛�YH�x�Ӽ��������.�k�i4:��.���#�̒��܎pCDg�-��9HV��P�킮�R���а"
-�G�{��pQ�DN�Krb�����ht�4]'�V�IK�23L�g�&�Pi�	*:���ڜ�(� �AG6r�&cr�>th��M�V��`d�vdGu;vY��~A�w�d�靽W���d�(�/�d�,ٯ�d�*ٯ�d�.�o�d��7�������u�C�F�!t�3��U�a��66΂��������ݝ�y6��4.���e��������j�*?�b:y̲6�z��-0�t��,�T�U��R�(B�EҀ�~���!q�]%�h�kNp�z�s0Q�GF�皝T���S/:Ʋ�Uټ�I�q*AGqՕ*s��+̍�J�x����c�}L��	�묺�P����gt��C:��óx xS����N�oʬ]$N�o�{g<d�6��,Ÿr�6��|,�#6C��,�v��}A���fh�)�Q���N����7�b<n3���Ř�[���G>S�j���U<h�9x���C4�U��@m�oM�;�����Ȓ��	cƓF�)v�Jt����
-K_U�䚂�0%#H(3w�w��L�87	L�{���O�ly$9e���_��{����$:��^,�8��{:����|M�f����Zo���s�i��}v;b?#egOhaȡ����k��Ӷ�C̱	]�v(�.�
-�R	�9>^�s
-*�8J/Q!8e�w�C�UeA%|	#��v�n�g��»���5 ��%?Z���[��Zvnq�o���,H=��2䵶�2��QF����'묙�P��S�z�_��Nd֙�RY� J|����Cn$��:2��� �:QĒ��K�r��j�0!���^h|P(
-��׋�!6ں�yh3Iou�+�QaA9t+�|M����k0��-:� �ާ�
-�&��%�K��8c��D�8��T��w܌.s��w���=�J�}���@��؊9G;?�ѐ*�ra4U0 ���Hʼ�ψ
-}���z����%^'�-��k���t�L��
-�"�btG$�/.̅�U1v3*;0 q,(�WE�GC����*-�Q���+�׳�9סmX&?���77��	��}P �����w?�����o�n���F����$���� a�ي���4�+�+@��#���*S��(�H�6u��_����3����U�W�!%de)�4���Ƭ�Fk�7N���Y#��(|��'�t���[���;v��(�,n��,.I�mΑ�v�0R��$��j�#qI�M@1���h��_Uی�w�]X局�$��e3.ʵf��g�o���f���`������ H2��N23�	3�l����)f�>���c#��E�̽Lm�t��4�^�%�
-�Qږ��� �`�<�z��))|��=%EF��
-�$i)2*�o��Q)��UҞ����%yW ^��G*�o�b�����~��8�J�\���䒕��?T��c���+4�Ә��Cq��rRN �)��+�� ���iȚ���W���`��b%��G�8��enX�@5��Z�q���Ml�~Z4\�����-������Y*�?aMA�Q�s`���<l�ʜj��ͣv��|��+�����X��g��������OҊ	�`���i՞��JdL:�Á�A1β�Q�^�۪��T
-϶�����j�5�����t����(�.�b/`�������f+z���\	��>A\;����~5�E4/j�7�ks��^��%^��8�93�*l��\�����`d;^�J�r�2:GX;W�,&�q��x�b�O2���J�	*0�0PO�*Jd[ _��ڭe o����U����3���
-t�c*�W�����*�R)�)��@v8�}t��R?��,�%����g�;� �X ����5��#@�ڱ�:�驴�«��gCik�A��'yE
-���l}o���E���EBl�yj����������V�� ��E���Z9R�������FH(qO	�H�����{�C�p���]�#m-��7��g�=��G~{���ܔ1�~Yư���g!�F��A�L��^�~T��@�Vbg��W�2½�i��
-���eA�v���,���VHm�0C���Às��b?�_5��s�y�k�����5Hq��ئ�Qp������
-�����'���2�[V@�{`��
-K�\R!8�,�7.�nb9v3(�[X@�����m�Ct�w$v��;�-2<>:ϗ`�f����|���������(��}"��#a%�&� +�����*y��N��>��mՉ
-P����d�K�|S�g\�/�9J��(�_��_6ým�A�,QF�s��-ARݞ?�zU؂+I[��TtĿP-lE�ؕ>62�;t"B���p��L�-�,���NpH�r����x�c��H=���ԋ]�f
-��'������n����q��wQv{�Ⱦ2�2�T[*��J��>d�����Q�H�;V�Kة�*.Tc�x}�8��Ŏ��h�L1v�H�I�r�]j�V�6[}�VGa�U
-\H�߭�J��֊?	���'�N7�ڣ
-L����/���u�7�N��[;yf���kٛ|78�x�@�����������8\�ο������!i-�	tt����l`�!�>�}%�	�˜�?�8t��gdnR��~������z��m8���;�~d����xJZ0Kj�s).~u	(��=��-jRJ�i�st�ϏO�4��<
-�3FlHuI.�%���[AV$����S�!���TCB�*dN�Cv�.	��N���^�����5�07�v�ף�/f���{+g�j�{���&bJ���J�vjA���E�AR���j���G���?�1��8����ˊu6
-T�$K.O�9�Lew�h����F�^>�.�Q)�>^"���'�����M�9�-t;
-v:�v�Xcן%�v������]	9[�]������b�y�v>��/Qg~��s���bŁ�|��Juᕪ�t��PGzf��,�.}����$,����A�D!>c$}���Θ!��-��Uj�j4��DlkhF� Q��[I_��^&>��9bqe���
-�4��sh�U;[AU;�<*T��si�ϥ��j��v��g��G���lJ�E8@vL�Xd��X;�=K���X�Vu��(����;_D��C�/:����L�]#��\@��y.�&�LR&�ㅄ���n����VC�����ZM�#�#)�E�>q!��:��d=���D��L�dE֋׉Ri�H����=t���a%��*.���hm�c�0G�cl�R��4��~�J�c�F+��U��(���Ȃ/pP��-��*��C�m ��w�!��+3�"�u�:
-<���r�6uİA�n��Ԫ]�X����m��"��tӫ�s�.zI����v���~o)�4�{���K��\G� �T�|.U��b�KX�Ḝ*Du\��2)]�7p�/EG�ѧ��-��=�������Vs�^s�^s�^s�^sE��sz7�*���F�},�4�r��V�
-˫h�=)Z��_����W)�~IҾ�"_K�W$�k)��]о�"�J��%�[)�~SҾ�"�K�%�{)�~W�~�"?J��%�G)2.�?��q)R��KZI�%�?������r�sI;Z�#����c�ȱr�+I;V�����H�Z9r��NҎ�#���$�x9r��M�N�#'�ᒬ�(GN��G��Ir�d9|���,GN��/:�S�ȩr�xY;U��&�O������r�dY;]��!�O��3�șr�tY;S��%�ϔ�����r�lY;[��#�ϕ�s�ȹr�|Y;W��'�/������r�bY;_�\ �/���ȅr�2 �r�"9<,kɑ���zY�X�\"����K�ȥr�*Y�T��Q�Q��(G.�����erdH_'kCrdX� k�rd��$k���z9|����#���e�r9r��U֮�#W���e�J9r��S֮��]&�׈�͸��C�
-�筤��MM?��nW�Ү�;����.U����Q�����$�n�R����b��n�i�˝<�Ozz\J_���O�Hkw�b�aHv�R��qrp�܉���
-X�G*��������Z����>�j9r�<�	�v
-fx���4fxْ�i��
-�z��`L,s���]ʜ�y��P�B��;}��P�c(厤?4b'A�#�������3��k��A�^73<�ްdx3�IC��c�ܣvޣ:�����xܞW齘{Մ���3-���V�'I?%�WMG`i���ƫ�#�Q��ܤ}������=�3���88��0���+��:�S��	�r�GM�<R�rڟő�� C�_<�{^I�~)4��Li
-��Ι��RP���g�*��iY�cK���L���8)	O�c���`<S^�w��_��A^�ȼ$ƽ0z��#�WŸ/R�=�N�Wg�>څ��v?�� w���8���-
-T�]�D0�ʕFf�x7黢�M
-��t;���N1�1e�Sq�\�2h�ܖ� j�2̰:�|��Ar�Ar� a�=4H�N 
-�4��]+�C��ݞz�r��bB�������C���6�}���2�j�{ۏ_Y߄
-�2����b��H�`���o8x7�_��zF�o����Q�z��}��!�:���(U!}]�g��������)�B�@��=3H_8É���3���p�3.�H�<8��!�X�ᔹ:�{B�=���ݫ��f��p���2���������8I_�\j�u��-�qi�g� �������1���n®r\�m�늍�>�奓'���[@�P8|�.
-%�<��n<��
-�c 
-+w�*�Vɐ�`��I��h��?�������|9��D�u!-��hr/:�``L �aL gct��ɘ ���a�|��'�ə�|ϝ���;Eg�N��O#v�K\�_i�N%l���;k��6hc���c����D��L�H��
-V��dq,��ڣ�
-?��8�3:Y�x�;����41
-zB���ވУ���zL5�f�[
�� �
-Z��]���dE�$��lf�IB��+�e r������"Z"�d�\(����19�IvqQ������E�]<�l5��b1����tc�1��R8r� 7��=�l꽌�l(���;dƞ��K����z�#�į,��Yڃ�$��ԑʡ�Dtϖt���4N��em@3?�8GҵG�K���5�m���_1����e��v|V�p�v�ĔD�a�&IP$y�O�`�ϐFF�3%Է�%���li�}\;U醖Q!&)�$w�c�H���gnI�*�;V��NEs*^P���4�r��}v"(�:ph�H�B�]���w�������&±����g/Y�y%������P	>�)�@NE��͒qs�J�C����X�"|iS�m*�3$ݜr����w��c��F��4ෛIgIgQ���~���]Z�q��&X!(�8v�.IRE���ivC��_ST�d\��Q�_m��ow����gw�������6]Z~}�*�!��X��qyfBN��{��Y�F]�KF7Ȼ�e�'�,�ǧ� ���:�U�+
-������izp^&`|j����k�f�L8
-���*����kхm4�QY-���-�=��v��L�'���Б��:�X��]��Ρ���!���F����Z|C����];6J�߭�m�Kj�ȭ,p�?�|�IW��$��� �-�$�n�=~�=�ӆ/��I�=ƴ�˧�g��%���iG��S�K{J��@ ����'�	i)J_�8��Z"�F�g<bDG1z��G����݂�M��0��Qh��~IP%�vD����{B���O�����-L-�M}*��H�_$'
-g�����*�1��x��>cm��[�lm-�����5iz�m��g
-$�3�zNW�k@_c̃o�b�7�B�[L�c�� ��k��N@QІ%Z�P}O �{@z��N�z`jg��@��T49�����+��Bk��ao;�1w;kf����m����{U��m��V�@7��w_�3���l��SU���}����Fݰ9�:��(l��M�&��{y��N��
-	�D�:a��L|o���	E�7l��g������p�Ԩ�J<_1��8��k�6�)�J舼�U�yF$k�ȑg��'���yN&k�!������P�|Y�%թ�ӡ�='x#.�SA��{�h�&�
-<�u�Pw�=˷�
-���(��q�0��X80�0����G�$�0�lq/��.^��WR������ +q��YC��ſ.�^^���=#V|�c�Q���Q �C�TT�EUux������Q:��
-�X���{I�"J�I���ԄpF�###ӷ!��;�B
-��P�X�"c���6 .g�x�y<��?B|�<>��
-�|f��q���x����)ǰ֘/�=X���哎�)Y(:�;�B>�$��.�*f��ق�S�������t=�l�X�Up�&:�8Ze�o�,��L���{��R�Qr8���_I���;D����
-|�����4Iy���x����|��4�����^����ӝz����ze�O������~��7^x�� ���^��ߠ �p����A�m|!_��^=�������,x�����u8�v��w1|���@�w�!����f;��[�'p|(_��Q��X!�O/���Y�o�2<=���l�=���c�:nK�T���ۅ�P>�bM��ց����Uax�<�+/'������8��S����s.�+�󨬜�U\W���rX����{����u6Sǻ~2��a�W5~z=�A��-x�Ux�� ���I/�q�D������c�8}�}�������z��ϊ���o
-��Q�y�l.??�\��;(�Y�?)�O��z���jiB��අ��F{�H��(��w��;�<��^yɂ/գ0|�~V���1	��Ƿ���Qߎ���Q�o�۱|�&��m���8��Z��m�R�D��&÷�zREUN1j�u���\|��
-�f'Y+_�ƺTى'���q�rH1\D1>���Cf���%��?�S8�$�o��rJ������@6Y��X0���HP����m��	��Yh���8��8���2���E�8���x�{�K4�x�äa�����q�qz{?�����~����.܁_��/f'^��,�h/�	���������y(���q�y	����u|t�j�E����«c[x�q�:j�%p�>n���`��Z�Wk�S���|���@<;���W���uL>&~��rlg�?e�J��_������w��Q��ɾ�ːH�Z �{��@��<�����y	��9/�V�K�&�%+/��o��yb�wF8�	X�#s^�ׇp�G἖b�-���G��(�ײ���~�xyp~����O~�2<:��Q9ςx��x/o�Ņ��,�S9o#��ށ�&�j֯r^�I�����}8��S��n\�Gp�r�yF8O<��m�g����q�Y���6�$���',���O����!�x~ޮ*�� ���$��^�8	^"ǋ�����缔���y%Q�<�����~+~NVn�)[���۸�L6w0����uX�?e�������mOǀ���2��j�j�8H&�z�l%p�.q~Kt�� �(ѥ�t��
-n�?s\KƸ���A��Gqr�U�,���K�lF�����||�y�(Wa�9g��t��]Ux�r��\��ⶢ�ֱ�y��K���V5nƼ�/��J�5o&|¼����1�ͦ�5����h��;9��vf���mΛ�獷��ْ���˟������,�DK9��[϶I�m��f�W��C�V5nƼ�/+�z}�y3��ׯ��1o �sy�dmG0m�L�`�W��m�e<&�g�_P��W�u�Z����_r�~�r8�l�Kb��|���1|f%�<��&��Lî����a�RKCKp~��%U�8)���*���r��vJ
-�(�F���Z��^+h"�Q�a�_�r��(g�jj�k�V9�ìQ��NS�:�y�[��q��q�/B�9����m���|!�qh�D)��-C�ݛKR�U*��V*m��u�~��o~�����7�R)��#�'��K��(u({�.�����B�
-t��9}導���rH|���t�Η�<���\����.>V�7VnJ���w\��H�j��p��o�f_��:��,������{� �>����p�خ�x�
-�'������_���l��W�p,/��wu�s���ie.�T��K%�ʒb>ӿB���eS�~6G"�O5�5/�7��O��s,����̦V����5��
-�@�+��e3I�=�I�:�ʡ�}�Tޓ�=���"��S�A��]��|��PM.��|?˓d�7ۚ���/�2����ɬ�?8�&�Gd����|���������B�X3��X��&�*4�[�d	����ߍ]s�+c��T�R�e3������>��c�>� �L�su�'0GSׁ��d2��T�Vd
-���/T�_�t���߇�wu���AFVs��D��Z̃<5�E���>�ެs/cx��M�!��`6���D�b�
-�y9$��(ȋr0��.�)
-&ۍ�d�Ө��ɭLQ�aQ>7����Ӡ*���7��]n�ؙ"Up/�ux�0��M��8�0^6V}�d&X��E|؉%������������e��T�<��0����ʽ�bscyO�<-�MK��Ʈ��,��(�|ruΙK��X�t/v!3p��^�2w�X��{q����Iq���$R��Ɗ	-�vQ͸b����М��l&A�h>l�L`I
-�"`qx�xcP��H�ҁ���%չ�M�Mg�>����؊%�QBledR�$_��R�Z
-Dnif@�@.P�5'�J���e����v�!h�mRc�9�Jg������b_l��b!����+R��Bq������c�}�|VB��DK���htΒ}�ѽV�
-���.��ec����տ����.h{�����y��T��JV94�zM�]�XU:�u!܌+R��i�t��s
-��h̏c�uu�������	�[�t�"$a�ܴX7tz���on���E�5{�f�R����cy	�)NMh*=�3�7b�5�k�):�Ty6˶MA��
-q���aP�v�S�˂�H�z�t�
-v!��6����{
-z��J�����\���T�m�Gi���A[�����H͋�3 �OẕW�~?����J�+fҙT��f$�z�ˀ���T;��c05�����l�A���5�b��?���KgJl�̇��ǈ߶�d���DP��B�-���']��4$}�2ɢ�#~-�"�+`5�l���<&�y�J�2ɔ/��bH�c�IU���Hz2�p�!�Cj�+�.�l�a_��M�X���:�-P�%���L�L�o-�O��X�b���] ��V�	5���4�@[��L?��IX"��0p=�f�e�Xٙ��H�jcL4��vJ��`ʗ��SY�f`��3���\>�$TY�ة��g��/�u3!ݻ2�Z���Z�",��tY_E�+�'&i�H���t=�F�u	ۢH��֡��m��`2�g�J���>�u}�E� �P�-O('RI�U��`_���؀M4W����p��Ʋ�)8��2E9�=�_̭X��S�
-D��\��>�e�fl������O�J vr&΂������T���u�۠.B	؆�>#"�`&��e�Jt2�s�|<��`���=ú���vrH����,���R��(O��^�Lr�D��(��J�<'�������n#�.���b�s���<�gp�2~7�,���������`��m��O��P�����d0Ngc��*�xA�2��lr���:Xʦ�E9�KU,��xxҾ����P�
-�[�E]���E9.?Y��߶��`p�pֳy���K�JM�g� Ȱ%k�b�[]�I��LA ���9E�@&`94��i���
-hVf�.�,o)��`5T���:�0�a���������CU% R���u!hN�j�`�N"�rةj�T��e��]HU0כMx�s�`I+���dj���+3��gS2q2�!
-�?���k�IS)3m ��P�ZF����fх�_���,G�����prd��@�"�4�����R$ �R��;�1c�L�ç�p
-��t�F��Z���,2��i���nJA��G!������N -���L?��̖0U���
-,Ti�\��(�U�O"��B"��z���~��k��v���[#�A�^8&��xG�5td^Jc�5��u���7� 
-�q�jf�t/l=��Jg��l[�r�����,e����S������D�/L �4����4�Y�>+;��M[��ma��8Χ8&B�%����Z�Y���zW��� ��X>��i2�/��a��t��ڍ9h���� ί[ ����̎\�Ѯ�P��
-q�Z�A�lK%^�5��G���
-�Y:����������tY	Ւ
-:�7k�ٳ9+
-����5J;�v66�v�M�)U���[�-�*
-&��Z�A���pM[
-�D
-@R
-ԕk���p���\a�z��ņ5Ђ��3�=׌�i�g@]U�5�`W�KfRt0�tgp�Rɮ��h��(7p؀ʿ
-�����B5�ˑG����,=�`�������z+��7�(s--�X�Y�b��ʃ��2;�tպ�O�c����|	���&`�q6{i�l.�֭����p�dd񯑊?�YP�G���w�>��؄*��I�Sã)���~O:d1l	���L7!� �ݿ�����Su̢��z���Ħ�7S�MaT���̲L�l�Z��Y
-B^v>�nLQ&�د���4
-�H�m�G����u&i3
-�'d?3
-��eJ#�7W!�2u�(4[�t�
-}(�:� ��ӜbD�s ��h��4��VC�lE�1�����ȴV	�Qf!�E��c�&�(q�fh�{��o��d�F�ts�%�#��g\���M���
-��_'������e�|���Π;�=W�L���t���.�3]!��r_!e��<�FSn#45���?`�M2K����������@�f����S�-�
-k*��ѰC���r6'�q�����̬@/�`�ϪSdr�����jdc���o�x�4O��t�V� �Iu`~���Z��N­�\��[4�¦���c ���d?��ԏT_��J��%�C���6X�]��e!����[������׍��I���f�z���� ��^HH|TOg
-vj�ь����(�=
-�I�,�g�>�+kt۵
-Bjnn��D�
-��Ot��7G��:�Z�����B��B
-kl���'��D�&&'X����
-ɽ#�͉ �V�ۓѫ�Z>9^訙�hY	Q]w�\8��b[ԙS'��)�*2O�i���ğZ+�
-k�M{�VUf¹o��`�t�e����S284��l'�7>�֪�n4�y�b>�f.;,����X�������Y�]��2ND����x,_�J�vQ_��8���Vpb֩U(�9�X߀}/�ނ@��:�d(�XA�@�30N�:��r���]p�tr�-���VK�t����]�o��*��5��]��i����%�n]7�1٢�UUp�J�=Z�/;+�{�I��V[��6����~�*2R�"j�*
-I��|V�_ j����m1_2\��jsP��Rn�����4g��d�PH5n�^�6`� �l��̻��2��EnF�]6-sS�z��߶*���t�k��&�-Z���sj���S�`�wCt�ٿ���~��������yX����/~���}��/��K����W���/f��ެ����iQ�O���4�7�X���$ ���O�d4�su��*,�E�F�`���T]��Azӟ�6y�ۨ�mT���͵KM�Нlj5V5ݔ'�V��uot���<�ӵ�
-Z,�ͭ�H�k��9�&�q�ũ�`����fA�f_�C������� �[b!^,�;(U��j�-�F�%{KrX�W�#��sֻЖ�V��I�
-V��4sҬ�Wg
-Ɣ�k)I�a�F�s�x���9�L������]h�
-8$:3E�����PpaI�!�]��J�֠6'`�'e[������v�9Ǻ����X�|��\� ��^u oǥ���f��co=X����
-Ѕ\?�#Y�J�ql��{����jn#��P��)=G�z�!�!7�$��w���u��������$T\��-^�D�)B�K	�(����L��p ��O�%�d]Jf�B>�P�?E�@g,����e����:,6u�͚o�f��U�cG��=;�ù�8���A�WG��|��֗�~ rJ ���U�V�A��]S'��6ڔ��_w?���V�$�?��D�3�F"�����s�)=8�zj>��z��&���j.��OґP)�Uh\�,��J��
-fV|�	�0�
-�D�x3�����dȃė��^����cf�5�����!F�
-4}.-�xnR
-t��q�;�������O�����s+4s�!98�������-�mU9�� �i��.�>�.z0�GW���&��N1ܴ�gU���Or�<��	��^=��f����;��Ě�y1�O�L�'����g�)&�k��o2׋ZW���6ư*g��e�mhi��63� ��n��U]B����.���D^�V�7m��u��r���1�6h�1�U���˲��z ��&�@qQeU�ɪ1���2]�'t��B�<�]�Q��Ӳ15Uf3^ƿ���/��K�,�X7_TŗWŏ�Fs�.�5��ѳ1:�a��¾�㭸k�X���;�`�j;Tsk��
-�E����:�N�N�ґ/j��'�g��FY��Q�{Fh��	��`T�|����$�~���-կ�j0D�Gm{�˾�y6�oYLE
-��K�L�
-2�
-1Ox&�� �j}ĖR[2������7o�*��WW�W�d��y&Q6&��23!,��Χ��XĶ�%��R}�%�˒�+ό�@��}'��C�,-JKh�_J[Z
-�|�P����]ι�$�������g��{����5����7��c��>�[�K-l,뵲��eJ��g!��e�#�2���;b�p�M�ja�@����4�۝Oy��K[���y�>��x�Bh�Ys�+(Yu��[)��Oz����4�Rk %�]IS[
-#����z�N��"s.��.�&WN�:N�ڣn^|�ש���8�7�K�q��K�^���kV�
-�I)t7�z|O���HhV#��'ym�$Ô0�0�0�G3�.o�v�.t�(�@ƹ�U��l� �ԝ
-�1��&�u�+�}�<��c���ID�iw��]�	��ݝ�^�;���{�EvܠC���G�|��dm��4�B!�.c��N�/Vo-�k�S��r�t�l�v���Ś�x�����C奒`��PD��"*�$�<@�Zކ���i�w���Ħ��&�oR6�y]Pr���4BgSqR�v��{��O�'H4[�,�0]�$��GM�������D�C16D.��Mrq;�	RV^���J����g�j8nH�Bʖg��L�%���sxjO6� F�G�T&�9o�v�'e�X��n�C.^�|ĬV����O�U�����(J��:i�b(mR�z0� �Hy3RE�.'�q<Cfc�dґK�ޜ%"թ��ѵԨ�a�I�0Jf�0k�.8�8�v���R��c���D("�ti�{������V��C|z��7��, ��yj�;�3IdgG�^h���żv۳��tϠ���x�@ئ��mt�h�+�.H@�:1�P�\�0��
-9A�.�
-�v��P
-�s]mH�M0Ҧ���	k���"� 
-���:Xi_.�s��6�9�G���=��Gh�3D/�*_5��և�K���ډ9$Z�~YOH���U�_j��l| E�@�''fƱ O�5`)� �(׻�PF�\�����{��=7�da��[EjXu��ɧr��݀��?S�ȉm�6\wW�8��
- VK�R핻�j������޶]o܆����x��gñ�G|�BU� g~ܦL��:�[ise3����(M��� ��%�$1*�DN�������h�iRtm5��Uq��q<*���F��:���'��HjHl:x�z3:	!�8'y�0������uü�9�������j��̽��N��$3[߀�f���z=��Ï?���Ku�buGe�~��G=�a��|Kȁ�uS&�v��]�c[�]ڊ�
-H�2�`O��=f�P��"7%�����*���)�4Q'V�kܔg�h���N��N�k��41O��U�ĥ��$5�ߺdjTH�r�g�y=iQ�b�-��i���%/6~K��;5Msz��Q7�L�~ԉI��;�Sf�$��C���`16%��ю3�×}����3$�箑��qN�M�#n��n˹�^%3�  Tt��L^�%�~�ᒀ��5��.�d'�cn���l{?q:+cM�v��������J�6$�I�5��2&����Y�KжB��+�v��4;kv��F����;�������T}L��h[kDʺ��$GjvT��y� X�/�g���Fi�7�	w�l�s���\�$=���F�?7�V�my�C�
-�ioN��pxL�q.1/��!;�uJ���!�y����XÙ�7��X��p�O3����Z�|��sg��)r�2�*�2l���Oe���b��®���$<�{p������M{�W%�Mn�FP��ج��B��B������Q+Ƣ.��ǡ�W{N��l���Dq�7
-S��L��ؔ˵�(��m"$ʗє+���I����&�A�df�z�����`_uY�f̑p_���|{�$F�;B����1i%pe	�x������3��F�{��u�A���*c�S{p��q�+���>8j�^uE��ͪ���� �\�XY%�,PdH��VE:���aG�q�`*�Đ3���G���u�Q�l�Vp��p��.C�ed�FX�KX�`=*�=��OVzD���i����á���������~�-�`]*�Oˀt#�٫���؈r<�|�ʦ.<$���y۹}�d}T=-U�O�׽
-j��`cE�nM�hݭ�O��l�4n��F����J
-!I����>G�vZ�;!�(J�Z��L�<e�
- )HIr��j���v��O�.�J�BKG���Y��\�N�ƷW�xĉ�zQ��u��v��;0�V䠆�H;%Ji��4OP��i z��pJTD�`0M����`�#�z���Sdcl]���Ō�9 g~�>�8"u�e!�/"��6���e�3L��}�rO�<��\��YN�K�6�_�
-41$:t'���'p�j����>��Σ��y,�~b�ǝ���6w�����s�B��ϙ,6#diD!�ۼ ��	�g�	v��=	<<��=#<�+&��\26S��%�Zq�&I8v�؉��!�VxR�eo�!� �)�&иi+�	U�.gc
-3�.ѕ�����Ԧ��-�Y	6/Vl�y��ٖ�R����:�r[��r���l�<�[d�=�
-_AH˯��`����z��l��Ҭ��$Oca�	Gi�iڢ��)-�~�4k�y�IF�]�M��
-9���,�M�bOnv��fɾ)��|
-3��!��mΩ�
-�1����'!A�,\��dd���
-9�pi�E}	D� �C/�~^(s�M�pA_+Q�0aO#0
-tt�$W�)΁�}dR�[�G�3%�ƈ��m���� �eE��D��x0r�JJ��Iaκ��4Χ�d�b�"�hL��Y'�%�Fe"��4DL�t
-�!�$�����K�taft�D�|S��OVw�n�&@C�b~m�Ao�
-diE3�9�^o�����a< !)���Δ���$�`����u��U/Æ�c7'�)�j򔎢�[�6��f�Ŷ�Z�G@��#� qG��|	�d�#��Ѣ�.�V˕e�a�c7��f�����b��T*T�VK���r���/��9if,i�T�u�6;��%���Y�e�
-	A>��"$������ba���t\��!��m�6�-��8�ϥ�`8�+����je��Z+����!��ڲu��P�`[�eQ�6o��`����>J[�Ī�u��3��mr����]����U=
-8�__Bw��[(,�ZҖ*�K3��������d2����`/⌄�"����a�t>�~7��,�!'��p0}�t(�EaO]nx1�Yfh���	�QO��5�4�G�UQX<�������m�=+��G��4? �b�%w�/F/3qS������#V`��m���	���:��N�8s%]q�q��l���ABm*��.��+����ܣ�ԇ�a�.�.�B��$�D%�P|���1D���[aY,�vP+���yy=
-�su8|�Y,t�K��:Fs��7�*�̒���MC%���I��bW���V�'�aғ����A�X^hn�SK��j�^��Y��R-K������j7��Cy�,�J��4�r@�I�r����D��L�<�K��}���A�C	�vם9���5.�e�A"�(�N'�Kx�\�ʋ�z�X4�=��VKx��]�D�� �W���R+c�PD�u>
-�V� I�����{�֦HPt����Kw&1'�e�Vx>�7[�xْk]\�x�AS�k�k�B{�u'r�[�U?Ш�
-2#o�x�E�앙c�6`i�a�h�o��m���k�&�8��Ch T�c��I=�O*�%k(�J7�OV���O���{s1L�L1͞�G�Q��y����2�|�T�vnoC��r���J�뼎1 �p)��J�>��e�Ixݦw���]*�y9	a��VKF԰�S0C���$�>g�[u��������I
-XTW)��Z�P]����vKDw�M����J��Qt#h['�-���Ȇ�Wu�����a��R�z�Z+-����X:UXM�����l�
-�	7����Jғ���\�rC��d�+��jH.@5O�3�EU�xkZ,�v3=�ҕ���JzZ���Sx�+���++���#㩠X�[�����+�咷𥼍.VU��b�$����
-���-�V���X�ǾD�P[��Ә�禧y��.-3��`�r��S���#=# v����m�](-����[�,O�UN�Ց��Zz0��*k5���L����;��g��i�F�}|nl�o]-��E.3:��9DS=�G�'��Zu��lW�3�ޗ�n� G�c��i�X:U9U9띓�
-�Ki��Y��ܨ�H�04K�,,���WO�k�z�Ո���;3������K�NS��:� _��R���1p���u�2睫U���;-�
-��z`�l/��\Y]*,���r�t����rړ��a���@�aé�W��@�K���T>[*z߃�Ney�܌
-Ӏ.飵
-Z����Y��b�� 8
-�nB��Z�������E/t���ص�hky"��
-��r�C�W���4*��GF���G9m��_a�t�<�ˌ�?3�!���qm50��JŃކ���SOvd�kN��::닕3&��J����̄���2#өR�����B�NP�"�3�ôX��Pפ��
-��h���n>��	�>Zj���k<3�\6<*�Ԏ)�gxQ��<��WVKx�.38n3D/M�����c@*p`r���Vjk�t��̤(��օ]��KẺIP搷��2?x�R���R�ކ2��Nx�L�2#	��P�̄���clVׄ�����R=S��-Lx'��[��}�M$� 'TN=��̇H{`�k�V+� ��dFx����� imd�u�y}`2����)�.�I�QY(/��D\�|��$��G�2��xҖK���3�S��.X�k���c��BlқpF2��ț�YrcR3����V@�8������.|�X��T�ґ1�5�\��X*kg`� ��
-��0�hz����~��L�	���	�,��Vl������e���5�8����u�$�4/)8El�+�p>���/B?� ��o���
-ޟ�C�y��J�������К�l	! mӄ4<|t��`M"J#U����[��\A~m-�?0���vW��ܒ�������r���6�zV�_�b�-�@xn�	�����7B%!���=bm!-�'S^E�=�a.!�M��0�E��"lݗ��w.�%Zg����﹠=zWH!���	\���@� ��$ZW	�1�B�f6(�L�a����d�i2/�F�ˋk������-;z�7�-vA�~��L%9M� �ًwk�z��ͽT�y#���ej,�[K�̓���w5��0��d=׻�#/OҙVf
--Q�B�'`�<2��3�T�.��ף�X��A�pӱ�cX[��m��vw�DY��x��(\�YEA� ��7���z�Q�<
-�����4��z�Cr#��B�|�օ�2�:���C����E۟��'�V7%!'C��Z[�RŶ:"����0�M�!N"i��� �m˶��5���Q�h��0 �!?a��mk����vgRv[����Mh}�ou�-���9�6�)��64{�ֵ�/Ė�4����!�Byb�,��Jt7C
-�DM
-օ�(+X��+�҅paW�u�f�BY����nE잣%�S�U�_�B�	�r73=qG¢�WЩ�%u��\T�"��� 	�-&�a��ʄ�v�@Ca5H	@Qދh& ˓=������u}��(ƴJ[M�QY��Iz>H��=�1
-֠�m�k��U�����Y>λ�����q[ko��4��)��lK煜3�3��t�����
-�GC(�̈��M���[[���+�I[kC��հG1��&Wǡ}T���E��'�D��{��z���@EXty*]��2S�@� �u8TBh\mVBgO9B��
-�)u�����K��?%*=�*�rY�B�a�M�+���u�	��!�@�����a�"��93"2�d{I�ld��b��"��Y�w�2����������5�4�t�R[�A'��ie/�ke���U�'�Ί�r��;ԅ4��lt�϶'@��O��FiW	�A��Jv�rj�Y�f���z,n��l[�ͮ��PpCn�$�8�e�]��;������P�����r��i�w����!�r�p��ai���U�#��9�V~���Uj���sgi�׭�^Ʈ �PHL�Z�AN��-��n�+k�P�#!G6Z�A�A�E����]2�l뷺�ε��<j�̵�\�7�m�Εkws�-��'�52]��lM�s���0[��:N4Ѐ�K�ǧSѽ��r�Ux�����S��w�}3,�xttd�l�>��f5�P�w<���e�\�]'n�q/��au�L\��lw_y� '�3:l�5�I#f�'���tF\L���������K�blvz$;!n^p��u�j�qi�V��PY*��i<'8��!��1�^��c�!&P`��#)z���h�~T�/5�b������������slN#��n��*�W�_e��r�S��� ,��c�A$�/�l) "8O��98��HG��8~���v�lO!rZz�w�
-t�aw:R��e�*첎�@cЧ�zU�<�YwE�p��H߬��w�
-fF����MF}"m)�I�џОL��F�]��������z��ݷ���E_�`ж"��_G�=~�� "G)'~��&Z���ñB'����q��]"�DY�A�� $8�wz�����h1�6Q�S~�D�?պ�=.�&���Ț��!j2��)����m+�ծD��ގ�j��k�[�&la��H��������Dy�L�pW��
-fmD4)����`�;_�gʄ���'�#3#~$����+»8���a'7��;��A���K�4b�98�r����	���7��J�݂��C���dO�1�ѵ7��\F��I՗C��{����A|K���?c�f�J�BR^&*��ȈM�M̮�F��|&��~�K��S��]9��5��aO�k툎E�g��A��Q`��xd#"�Ɓ��qčX�\�e߿��ɫ��pt]��>��w`��ltH"�l�m�Ɋ�H�)��(�����p����p���Gx/�-̐fhc��α�|Z̸FE�gj���fƚ�� '�ozt5�u�v�Ⱂcuĭ�C�m�;o�l�gh��s?��,x̚����a��)B6h��	��,��ƻe͢�:�
-� ��$��d �VdD��4F6D�����:w�1B0�D��q���8�a���C�?��f�B��mtr���j\�2p��,V�m5���l�b��O�5m2d��v�H�
-�q��x�7y�㮨g#�p��Z���_'r�1Rغ��\�H�N%�u�QJ/� t,]�O�Y�
-�
-Ή(z�g��k������M����A�T���0r�QN�M�D��H���D�5	���E3�x�\��DB`��Z�hF�؉��X�c��C�f�e�"&K˸,��qW
-��nm���_
-�х%b��F�ODa���}ġ�ţ<'�p�J8LE6���T��@O#S���X��k+��k3��(Ta�+l�#&-sp4��;��f�]��{�l�7q�D�
-o�-���"�k���(��7��E���+�V`�͑���2 *��J�%|�c�Ɲ�Aɬ�!:�SV�v��*9�tU����y#�WCl)�D[o1>���\ � ��1i�!A�gC�Z�Eh�	�ao�w�
-V+a	J�ܚI9ɔ�~Dq��#�u�� (V�-Gѕ#>[N���6a෎����WR�J����	���M8G��~�c
-|�a)S#Ѓ(:�B�r�(��}�^-f�(U��r�P���zۭB�'bBFmOw��c����J "M	���5��B�4i�a����|3?!>�����ǌ���E��,4c���\FCte��J��˖��C�u���a4�2���A��!�@
-Zh�"$�Y.�5_��UDJ�`�;��k~�rѐ�N��C#�� VU.j�'Ľ�,~2Φ\����o5��Ԉ<��6sq9��F����e��J�9�"��-�	�rO�
-zdg��Kk�6l����[�T�I�rDD�E� ��%��W2L��!������Z�m�҅�K
-�Iܶ���ʨ�~�`�ھh01)�$?�z�am+��ah70ȓ'V������c9�1!�a��x�E,�S�AJ��
-mؤƈ���y�#´m�J_���w`=��pV,��ÿA�g��༐_��Rl�H����$���k�d8�a�ڱS�N�b�hK�S��I2��G^\�e�&x�a±��'-��e��8ڡ*�{+,oJ.��d�0]�!d����Yf!��'	s���A��<@<�=�Kg�3R�!��@H?3�rs��w({J�����í�9��y��V����A>=��S5��Z�@+z���?�"�@w ��
-[�N_P��A	�1���ƻ�X�_ȇ"q���w�ȸ��E��R33��~`��̂l
-<��c��؅�n�x�J��0U�}�O�"ν����A���Ho�혋) 
-���:E�x����(x���:�5[�扛n2$�D:�f��R�V�P�q�|R�a�&�,���9ꭢ8���y��I_��L,���VKgU�f��2p(����{��
-b�6�ł��6
-~o�s��}O.L�g�=�K�۷���<���L�QE�R���	aH���������`q�&�d'ǀ��ٝh, hx���;�\�.!j
-v��Ju{+���zB���X�r1ؑ!��A���oT�uî�n�5����:Lymco��`�ڰ�>�`��������@k�.4 �NW����j�[�����?p�Ҷ{�T��i;��mgz��T0��`�li��T����;�Zw2�
-4�#h~7h�g��a��q��I����yw�|Z�|z
-�2�2�2_2_2^2^2�2�7&~5d�s��������Ð���_!�P2l>3l>;l�6�6���/
-/�/C�W��+��k�� h|4l|1l~%l~-l�K��F��&�x]�|}��1b�9b�������1?1�0b�i��<�|��~2�1�)b~
-g�܇?/J��J��I��K��O�oJ�oF�R�S�0������7)�oS�/�̯��H_K��2��2��2�����̟�̟�̟���N�L����M��������i���{ә��������͏���p�ci������_��/a���Ͽ��������]�����Ӧ!��i�i�9��}��K��W ���曧qG0�=m�g��!��9���3{#q�x�l���=��{g�ϙ�>w6{�l�y���g���o�5�;k�o�����Y���g�_���?(��I��z���eFɼ�P�U�2�>�y͡�ke���1�?��}����)<��md�y% p�����N��m&��L����~�Ⱦ2�\��M%����ó��d_�~
-K�&��.��<*��D�K��;B����tX�Y\�Y\�Y\�3��o�g~�d��~12sU��ײߤ@�y��f�dq��T���f�g����U�߻
-b�g?ϾP�_����g��?�
-_�q\z�,~�?���?�gq�ͼ!��u��E6��D����W���Gٯ_m|�j�_1��D����TWS�R�/�٧Oo���2�_��y����T��SY\Y\��E���!�}s*���
-�My	�C�_Q��-y��.����Rަ��@�CPG��۵��q��FfVR�S%��r��oB��wj��)�!���('C��_+����GS��{��z��~�B��^QR���>D��?)'��(��E>����.�5E�m꣐�g�c�?����o*׾�|������I�Z�
-]�R�����z�=|��?Xֵ�u���]}��Q��u�&=zL׎���u�az�=���H=~B�?ZW���5]�u=vR��O=X�}�tߜ�u��k�z��_��ѣ��ꢮ.�Ɋ����c��>U�S���]?����O?Q��
-�^��G_�+�y<���5�����zx� ��y<o��-�����vx����&<���y<��=�����~x> ���<�
-
-`4Ǎ��P�`<L��0	&�(��3
-K`���4@{�Z�K�*å�0P�.+��]-i�{-�ÿ?�Jm�ވM��	{T��
-۰(�؉�w7�\�^�^���� �Cp*��B��='�O��=��ոg�����s��9�q�_�O�κ���u�*�נ����i���M�[p��]���<$�+�I7����g�K\��.=qy�d��J�����[�����n��q�����;wn>�p��#qG�҇t)��Q�q��X(���q�;w"�$�ɸSp�8~*�4��3pgzM�b�Y�铲f�҇����Þ���"�Œw	,�e��0��.+8W�r�+qW�j�5R>��`�l��ÿw.}J�F�ji;���]6��w+.�@�m������vlz����]�2J�'wك��4��Lu�'p �!8L9+��*8ǉ;�{N�i�&l�2��PW5�gq��y� �
-¶����6���{'�.�����݋�~�p�?�{�*���TT��Gp�X�~��U���?�{�$�)�ӸոTG���gq�M���喩�p�E�\���W��W	����u��7qo��ƽ�{�jκ�{�\����RNC������'.�Xq��8);���N��MO��MO��MO���N��^c(x���5����f_[!]4y�w/荝��Xc^�KX?�` �<C`(3�|�1#���0�ܱP���'��0	�d�9�0��׋�
-�`:̀���bc�x���<7ǘ/ͅyƼ1�B(�E����Ÿ,��(�]JZ��/q�_��z�1orܛ+�c���79��2(���
-V������`3l!U����؆�v`���E�q��e��/S�_�_�_�K�2eys/���;�{�a�$�#�G����*�9�}��'�1_=���@
-(�rܕ��`5��7���u�6�1ޤn�7�n���V�R��n%n�v�o~ iwb���o̞x���x�:�
-��q8'�͏Nឆ�x��L���9�ds�
-��S��~Vo~vn�M���܅{p��x;CYfy�&`Ϳ���?7ǚ�EXo�\k~���ǚ����� �Y�����0��༬6�G�(��Z)�
-E��qb�� 2Qd��d�Qr���D��L�.2Cd�H��,��"sD���/�@�@�[(V��"��"�"�%�N2O-�R�e"�EV������Y%�Zd��Z�u"�E6�W)�Id����r�3E�Ef�0W�S�Wjm��>��v@�mbmwK�Cvp�v�M�n���o�H�?D��>��~1�	�������a�J�#~c�rێ��s�o��oF�"y�:-�x�:(R-�Cb��F��9�u^�����^�$rY�D�v�s��9+rE�\�F#��T7�f���G�~����-�)�%k��+G��~��}�"E�& �D��0i�#�8�	̲�
-�^��^.��	f��o����`&�Ay	f��`R�%؅*�I
-d�&(���X͗j� E�H��rz9���X-Y�o�%��X�1CFs)���8���3K�,�T�e"�EV������Y%�Zd��Z�u"�E6�l�$�Yd�H��V�m"�Ev$���̖���jW�[d��^�}"�E�9�uЋ�JܣP���8M�T����p.��:�{.¥�P]N0Wĸ*rM����b�H0�M|�඄�!��b����E�&�6Hd� =	�I@�9��荑�H�}��W��x�s� (�#�%�2�΃�0Qf�r�P�a"�"�EF��%R 2:�$�I4%�]�b
-נ��
-���l�Z��q$�d�c'!\��]��sqH%��]���=C��K��� $��a�J77���Tr�8�T,A�^j��9��"t�U�V�B����N����j85r�Y�sp.�E���$�/Y��#rU®��~�T�Xץp7Dn����ҜPwE��y �P�k�M��H�$z5�OF/�
-��"�D����5�r'��d��E���(�jf2�G��I欚�d�I��j^�9/�^��&�I�\T����"��*k���s��.�,��J�˒��B�L�\d��*�]
-�1�Q5S��a��T�ŀy�2\
-��������G�}x �k+��b�%F�VF6E&鞄d��o��`���K���W-ir11s�{F�bԈ���1�ѧ!�Q��c�� "�K���� |���@ҋp����������@
-�$"_d8�0FA��10
-a��	0&�d�"�L�&2]���I��dS��Y$ۚEzv22'٤�M��TS��'#t��(E�Z%�f�^,R*�Ddi�yo�H6ez%�V��c�k1։�cC�Iژl���lv-���ے�j�Cd��.R�c��^�}"��M��f��bM�G*�:"rTd�A��:&r\�D��p2�<s:�l�gȿ�&�M�<�ĸ�l|�ĸ,r���b\�8,F-F��1��q�3����Ub�"�6�
-�8����><���5Ũn�#�<�3ŎU-M��IAz����нSL���!F�m����x���z c�H�!0�A>�Q���S�)潑P c��S�=4&�/��AV����"�D&��E���L%�ibH��"c��N��)&i&�a�M1�y)6�g*��d�HI��Z$�b�R�%"KE��,YA2��L<�xV�cm��Z�{w5�
-�+V?�	�Ȥxs]HE�eL57�ڲ�RM��TsK*2L$?ը�b�)2J�@d����"�"�DƋL�Љ0	&K��"|SaL��TsW�J5��Ts_�K5m�2�*!jq������P���,I5=�e�X�EF:�
-��DF��\��"�]%�j�5"kE�K�:��s���*�Md�GZ�k��lĳIRo�'�w̓[^�L��C��V<�SM���I=�N5��B�����>B�Ku�Ѓ���C���S)rD�H��1��"'DN��9-R-�:gĪ9+r.�$�O�������\LE.��~NEK�y(�݇�b�9z�eI5ܘ�+�f�S+r]��M�["�E�ܥ��`�<��R͟<L5���if��3�a�V��f:��;��;<��>i�~D��0�`p�q���|�f
-��$d�X�*��0F�b���0!͌u&�L�BPL�i0f φ�)	�řB�XR����F�!sE��Y�f��Q"�Hd�H����"��h�����NpVR�d�VI�j��Y��6�F��aK��RA�V�m�{�;�w�n�{	߇�����a��#p�Hs�c�����	��p
-���;5pΥ�p���p��\�&R+r��d�6k�LqY�f�n�bI:ٹI�[p���43�
-��ɶ�n����	3KN8��,�Ed��>��"D�z��q�Tr����dyN�i��3PC��'�\���'�<��.���0�$���.rC��-��"wD������ B�'i5�z@OȆ����\�>��B?��� a��a�!��1���'�g8�0R<�D
-DF���1X��%E!��	0	��T���Y�^�L<�0f�q��ę�1�I�HR-v�Η"@	,��P
-K`),�2X	��4�j��:��"D6�lz��߫D��Xm��-""[E��l'��S<�Dv���)�6\*ͻ�m��6���D�pA%�cpNA5��9� ��
-\��pn�]��kk�*�hm����f���׫��ꍛ}�?�<C`(�|��#a��10
-[�3�vzF�ܖ�����\T�E&p��֦VM,�}��.KMim�:E�3��g:��	�0Kg���K�<�$`�H��"��"�"KD򓐥b-km�I�I񖋵\,�m�U�rXeP+[�%]�*1V������Y'������%n���z�f��wl����]�I�[d��^���~8����������\�T�fy>H�H��.��vΎ��8���pζ6e�9���.��֦ܹ$!�[��Ε�f�t�YW[��&R+r]���>+ބ[z[��]�{"�Ex.h�>���[��j�چ��C�	ِ� �@?�a��`�`x�ڝ�,��H��62O�(�1P�aLlc�&�Nnc�8SD�D��L#|:̀�P�$b6���`>,��P�`1��X
-�`9��2(���
-V�X�`=l���	6�����
-Up��	8	��4T����p�����2\��p
-� ?hv:�7�H4i����1�c���.gb�N"{5��)P��ƙ�ε8��/21�{�љG��0HyJ�f�,L��	)�U�૎=�$��Z���1:�1��n^n.��~��EȊ ���2hڬ�]-���N�W�Am&pTm7o�8�5�V9�e''��6�ҝ��
-�;�_�[����]
-�I����{
-�4T��X���N��y[��=��<w����v�?#�Z�g�Cث?�B����3��g����u/�vN
-q#�d�$�[���=y��9�ŻG#wĺ+29�'��Ƴk{��֞!�3vf�g�Q�c�q�'�ml-�~�Ou��I�O��oo{$$��6�WB�ͅ~	��Ay�_��K�~�OȰ/�����')8���<10����i�ן��|�-mO%�Ꝉq�S��7�t<3�3������,��I�l�9���^�c?i��i;.��������"rSEƊ�-2^bǉl��q�Ge��	�p��Dd��4�2iG$�E�%Ң�%l����-a[E�K��V,2Kd����"���$�I��vQ���~_���1�vqU��<���3/�<S��37�������8�=�_۞�
-(���
-�`5l�{���)�Ґ����~Q��%�"��󳶔����d�%���vL��U��;N��=ܾ���w��LӶ�Gڛ�G��*��B�'���S��i«����d�����Ş��_�.��,ǝv�q���f����\/�[]jO�	b�;�{L�Y�U���a�o������M���V�x&��Ip�}��Fݕk���{fj�?|٨�f�w�H��`ↈ�Ju���Ԍ'�^�á��2��˴���jdf�/�����/������^�HVOK��%����>ɍq�w�{���X�
-EƉ�� 2�C��$L��vwp9{M��)�{�)��tI>Cd�H�{>�9"s;��yb��`�-_��"��"�"=d�XK;0rI��^�q���QE�NJrl��
-K�WX����l���{���
-������{�NKz�Ü�ׂ����ە0ߗ��$��u��u첤׌Z����]-��gi~�����`�����N��B�
-�L\)�:�
-�E��뀜� �|��8�;p3߲�;�e�e]]�IG�v@��y�z
-By��q���R~���mU��<{o3�m�da������n�f��6S��mn�۶���ڿ�@�3���1*�edP̔��)�H��W%v�D�o���{/��k���B��׃ߐu"
-����Ю���C��y��������8<㡛��V<�a�C;��!�v{܇v��Ab��gZl}ڞO�$m~�����̖'a����?�\���x�)�K��=�{Hd�x���u#D��9(r���Gt������������*��+��.Wݔ}�*���+;�
-�Iki{�i�'�g���3Q�Ikc�('�C�R���.K�V�8-G{){09 R�G�)q�G���*ֈ�s$�i�@���?�}�T�8�������������f_wP|s���6���_��J��&*!�����c�Ѷ���{<Z�}��xė��C$3�1�d����B"Z��Ɨ�DM<�h)�I#)\�ؿh�1�!QC���F��ܥ�M����l%���k��С��F�jS�̓,����aitMM����=�鈖�S:O��q�7�E���p
-'EM%Y���/�~�ړ����D��~�߀�F�����5ۆ������n]Ѩث��!_�����F�*��Q�ϗK����x�S�t	H>>�N4ڈ�ޝƝx��v��O�5J~bd|̖�4Ѭ���>�S/�q�o\��6�>�$�C�Ox�Q�1o�'h\^{S23	���M%�֢n���h�>��!�Q��#�D#��������
-RJ,�;\E�܄�H���]C�N���s�H�U/i�э��8[��]�z��ްD����{�������o��-�ß����蜘:{��<�H<φK��2��p��GL��N�wHs�n�
-_���I����D��T�O�
-�FԽ��^o�a���#�er�Ҙ���>#r|h�
-VWס���'�fh�ʑG*"<��P�ΒCg_�[��t�un'�u�)t����J�2��_��*�Wc
-]j44潄��$������c?����~�U���׶��)�w�41/��f���O�;��Bx������/�B/�}�>+�R��}�0�q���۩n�6=���lb�a�E��������ܗ0�c���k��.M���Y�{r�����G��k� �K��c{��ӳp�/�q%ZgM~z-r���1�\�#���\��]gY�`wM�����st���$��9ӿv�~����E(ߖ:<e���}x��6�FwU��j ���ߢ���������3��s��m�H�u[t�9t$��_�4�����L�[dF^��
-�ԡ��T̴���O��6��n���(���������e�������^�?�� Z;���ว�O�_7�=��Ѩ��0lr�7��&�����ibh��DWR�����7Z%�
-�O;i��hJ�����p'z��^�;�c��]����׍p�W�����8+��[㕉�DG����_�ӡwp�D(�c���j����)'��a���TxR️�R��2��~�����prU�9��O�O[�哛h��Է7u��}��8Y2�J�t��_�m�Ӌ��}���(�}�z��e֓�~P������4u5�����63����B��Q�D���F��F�yݠ��.�z��G����ވL�B�Pʉ�%>��u�pvn��#��U�T���E���O�"Gx���WT��D	vl�
-D�NQ��^�Z}܃c~L�i�7|�T��7�%��-��8���E�����]�������#�;p���f��G�����
-o�ɯ����wQw�#�ݹ��F<��2@5�j�n�خ�+j)�W����3�F7�c~aP�tI��s�Pn�]7<���)͜V�7~���v�����d�jn=�<y�cT�{�G�CW���
-�P�m���cͳ��Ż������c����~���s�������8Q'<��1�U���#�>�Q�G�C�7�u<��Z�����#��CFfy�\�S �@�c���TtzhZ�G��ׁaj���"mz�P�M�� p�A��I���9�������.�C�W��M(�F�Q��z{b���@�/�<�M}3��6���ٯ��o���>���ޑ��C�A$�� 	B��q^Rk��>m����<�N ��{�:�9�S��P*'�YT�VZ����Rx&.ϗ��v=Oݖ�ۓD^T���������n;s5�U�6�7�>ّ�(�~��^�U��&t��nN��f�]N�_v�o�;u�~~����4���Z\8�'�W���'b����������}�W�}x�U��Mbkk�z�k��/o~��45�z!�Ko��6��<�U�E����~���@�V�Ope�/�C�f�P1�`G��!����6�nc�Wbͽ�
-Խ��m�n��%+�����������ۍ
-�	F�*|'�1�9�:��Ǳ�Q�~�v
-�ڑ��4�%�#�5��#���pM)}_��q}�0'�,a7�97�<a<V���R��`�.�j��w�%y��.�/xO]!�R�
-��N�<DS<]�5�nh����
-G>})#z�.#�B�;n\I�V���mzU�WS��Z�\M��&�n-�v����BA�I�[��������H��z#A���P�f���͎�
-[BA��[CA�:��T��K�g��*����z����*�vvL��w\�V���{��*y�Sz/����c�̓�������==ӳw�>�����'ɲ%G~N��Uz?�rR%K�ǥ(�ryK�;�*�R�	v� ���;@ A\@�	w  @,�J�;�=�]�r%�|�ӷo��ܭ���o�k�0�_��3�_��(t�q�(t��w\��%��}ݲa��ơ[AH�Э>p�tko�/�I���n� ����0|�i�6
-�4h
-�t��fˀ�H̀�X̄\"fI<���Q*f�B���O�su�_)��,���G��E!��b�$�y(�+B0Ub��b�t�Ո%`�X
-։e`�X6�`�X)��I���j��X^k��!���`�� ^��b�.6�7�+�M�*xKD%A�
-���;�5�x�'����
-�:������l�J�&�l���+R9xU� [�J�U��_N������ȭ��n�j�kR������R���]joH��M�
-xK�
-vH-�m��#��w�k�=�:�)������&�%�J�#�6�-�Kw�'�=�G�{���S��'u���Cp@zJ����|&=�K=��|)=_I}�k�|#
-NK���=|~���Yi�x��I��ؼ4.H�����E�#�$M����"}B��,|��߱/�4� E��c?6�\ؒ>�miܑ��]iܓV�g_Z��Pd���G��XZ��Dڀm�c�[`�q�3���]0��&��$��l<����1x�x��e؋1L3Ƃ��8��2��`�1�,c"�m��|�_d��p�1IY�1�e�b<���υ�2���5�R�E�ʌi`�1�0f���L�ʘ%SM�k�9`�1�3^�y2_j5J�V��2�uŘ�kW�д��P$7n
-�m��~LI1�0��&����S)�.�q�r�\a:�nȕ&��r�[r5����e�ޑi�{W��=�~:�Z�\>�i�%�C~(7 �Gr#B薛��r3�D���W�^�|*��}r�/_���|�
-[���B^��NY�}pI~`"K�W���\��Md��u�	�!���r/�%?��>pG�w�pO��!�@~���#�x,�O�W`��5czƚނq�a0�4&�F�D�;���=�B�i�d�8�����x�4	�������`�iL7͘���O�,�g�̙�<�[��l�v�h"�]2��BW����٦U<9Ǵ�5_��5}��i�j�m��AVk~u��֔m:�������B�6Xd�A\�����~wW�9l�?��~�_8�u���۪݉6�K1pb�,�LMp��Z�3�h�E�$3�T2�z��`Բ���M߱
-S-Z�JS
-�*�+Ԇj��Ɣb��՚���X����7]0��T3�E��4��5��u�0MM��&S�E&.7�_1eqM64WM�f�����ZM9泬�DVr͔����n�o����4Q��e�z�a* o�.��S>x�D6}�D6�i*0c,l*���.S1��T>2��ݦ2�|b� {L�`��
-|j��L5`��0ՙwL��7&_���0�`�	7r6��[��fZs���uO�<A#��`���3���Mm���8n�~0�����	�M����n"��L�����n�״��f��>�n�E��l�@�C���Q�#��R�������k#��܉�O7�7�{�f��4��0w�əf�w�?f9f�!��{������	��9�k6{���.��^��7�������s��Y>���͎A����!s�����uA��L����fZ��@�l�/��������r��՘�H��5�Sg~O���W�Q�̻��h��&�.7�G!_1��|��l1�4`bf��fv"B����2n�(�3�;��H��|ԝi�ڌ�|ҝY2/�8g�W���<A/���o�Ԛ'�Eh@A��\f�E�y�@%2G/�̟ ? 1�5/C~��1�B�
-��U3-@��b�� ����"=7�s�4/�м4o���+�4���f�f�4o�;м5��܃fؼ͈y�� |g>��n>��n>��n>��n�¬f�L��Is�"�)3��?�c O�c�s��Κ�9s"8oN���g�yET��!]�'*�#RcO�'�.p�Ү7vQ�V/
-0N�D��!�QX��W��WX��_*��5)Z����N���+߱f�^A�4�W�F�Ei��<�ڔf���s�rr;x��P��7��>sܪ�:*�
-��҆��V�!&��=Pp*���)B;�ح�@��֣����s֧7^�ˣ�6����'���`�CJ ɞT����6��R�����܅�D�Q���J'8��G��;�|�<�Ą�+���18�\D�_	O���Ë�A~R��"�<��s� �9e�*�2D�Ey���Ö�9����@��-�VG$�߱�)*�˲6�������+���Z�oy���Q#
-u���_��ſ��+�8�)�:�=�;�9�c�����L�,�ʤ�2��o�sJ/jZ,,��ba��#�^f��-3���ݵ Ţ��$ף���E����sR��-����"~��E=�p�������Kx���edՠe�2dY�U�5�Z�/\^���>��-�m�����{\�ϟy�y��!	�,��s�	��m�KK����āo,��[K8l	�E��hASbI�`:mI�<b:mI���t�r�%�E��r�L[R��E�%
-��J�<X��ڶ �����-�u���mK�@��lː�l+`3(�+�U�WALlk�[A��پ@���mr;���m�M�&�"��b`eۦZb`eہ|��ʶ�>���mr�m|h; �X�!?1��A�E�k;F=xj;�l�VLl1��-�ŁC�x�-|nK_ؒ���d��<�ږ��] ��R�a�EpĖ��ҭh�@4o��c �7[&� �7[�I�[6� ���3 &�\ȳ���l� σ"[��A��l�v�(�e[>�[�j+�lE�[1�n+7l�Vњ�����YO�F�aw�[�!�଴R�_Ed�/�^c�:�ɱ�Z1I��!�K�z0�� ^�7���&��N#�B{�UTr1`��+�.a�nG{�Q�Ќ�
-I(E5r������8ش��rT�0�����ZW!�"��FV�0�ᡥ�9<��1��U�r�ڔX��Z�g��AX�6:LK�v.���&��f�
-¿�X����5���wա�9��V�
-o�;7y��:��:��ݱ��o8vp�M�.x˱v8��v��Gi�=���M��N�%a��+��|���=tA~X���c��q��h|�6T>���D�s�BQ�q����|�x�/@T>G�W���v��ao@{�H�<؈#�(���q�{��#�8���q�p���������#
-�C�GD�.�y6tE���|�F �uG�pB�QEE��ATQG��U���\�s�^�}��;p�^�C��;r�^�c��;q��g��w�8� ǂ臝��AKpV@N
-�u����a4���A�m Q�r�AX�sr���Dw�|�[z�/�^�K����|
-f�.�9�40ו^re�y�L�+�we���Е�.�[�sp�ǔ�X��x���ހ��9V�؜cU�<Ġ�u���βZW�ITn
-B���e˷�7Hgaƍ.Z,jr��ͮR�����1�&\�`��ls�Ӯ'W�q�UM���.Z;`
-.V�6L�Ŋ��rG�r����u���h��m��r��͇�Z�s���n�4m�t��'�	�6�{]�i��k�sM��.ڻ7�}��.�'9䚃��E��h��m;{�����-��E;߸h��[m�v��䛁�"�9�h��{ms��f��a��zy��q�t���)�]��-��.�;�}_�\�7l�E���\�oj�Eۅ\�q䳋�O.�hc咋�#-�h?Ҋ��g�U��z1*��\�F��*�~ٖ���]�8�㢅�]-��h�u�E��.ZH=tѢꑋR�]��z���:Z� c��cATv�V��UZQNP?CN1�V� '���Ѵ���[�@|RA̿�J�i ��j,�d�"�Tqo(�luO�E��V��%Pdyj5�r��j�ZK�\��Z���O�� �XmK�&hJA���
-Ժru�v5�͸Z�VAS�^�\�Ҿ����ժ��_�Ү�z���5��#�Q��zz�\�����NTn�H�Ԧ�%]Sɒ�����v����fG�v[0@g�u���]�t��7�N�&���-���a�(]�����vj��p��v:G���=�{��^5vr�����ؿ%��]��#��*F��w��~d����˿�����c��������K��9�R{xh����*�:��}��r��}�
-����_����FT�j������u��;U�9�^����;�
-�,c\��	��A�ˁ	��AL�ȕ)u��tH�<h�m�C��5�O*��Ϊ��oN}Ϋ/�s&�ݑj����
-c	�ϲe�%<����U�5�����o�uu�����iK��1�F���6aN��m��o�F�u�4�vy���_O���U:Y �R�ٿn>T���G���L>�|��q_��9Z~��1�h�\G۞c5�/Ӷ�8���6�xM�/��I�&�nOM���P��K�&��������R5��2f�杦�E�$�E�O�?6�9g�5�y=ݭ�ڙ�]�Fy��-P��}�nG[�nG[�nG[&��V� �U2Hm�R�Bݎ�N�m�Aj�`��/D�9�Qs��#�-��q�>���9.��L������<�<�<�����֭Y�����oc�hW�8�=6VW�9��!�A�N��+Qy��As$�簝%9��2YW�w|�r������T]u��-1������B�����)��O�S�9�9g9�/��k�K�@�Ҩ�;��\����]�2"��e:�kY`��
-�x��\O9x�S�y*�˞*0�S
-9�K���_ 'x�Hu������$/��L���O�B?�}�e*�/��/�bK�RA]�RA�y�"Sӽ�d(�0�;�r)�0/{Gٲ��߻�N�1�'s�~ s�N��x']�3�
-4�*�N�&]ʆ`*5|{��U���]����J}ҝYo9��|/��.��.p�����E���"��RqTy)���K��X���9�Z�24u��޻��z&��Kg"�k<T:��#��^:y�K'��z�P��N�z�P��Ԯy�$�u���S��^Z\��]G]����A+m�������t�Y��4������^Zo����N/����n���?��^��wyi���KC�G�m=�<�ۻ���wWϫ=��x�����~<Bk`�^Z�{�=p}=?�������o�?�%��!�!/��=��j�s/����j�K/բW^Z�{��5�7^~���5{�^�x�ʞ���y�]_w$��Ҏ�1�ɷ�e�K��o������NqOzip�K3�^Z���Rǌ7F剢v蓗ڡYo������7N�z|v�K
-&�.��>j�|�:&��E<�K�>ŗ^�e���L�9�|Y��/I��h)5×���>:ϖ�sq�>:��sq�>:w�G���|t.������o�����rT��[�����\�x��T7/s�d�*u����R_�Jk"Ő�|Ū��}%Ȭ
-_)�R�+�|�`����U���*��W���:E�V�`jUVǟX�RY5p��J�5�7s��6�/��X��FD;�x�_¼�k[|m`����^��}7�v�M�Ǿ�n�xw���������PE� ݎ�ݦ�8�,U�6ʽ��݁�����#�7>�==����݇�)�zډ 
-3>WO�$�|d��>��9�¼�la�G�2��o,�"�%_��,[�QMZ�Ѧ�UC]��i�/>:����G��������F0��Ǵ�7���|�'Ȉc_x��E�,�/=U�ug?8��A8���D��g��,�ϞCJF��g1�2/ԋ��~�rs��/��E���-�0��(/�w\~�9�9���W�	.O�ԬLqӧ��4�GT�t��?���@�韁&��I���e�)�s��\3?��9����h���\�F~���)�/A.�/�E��ؿ
-����R��̿��7�
-�&Ux�Ux�6Ux�Ux�.Ux�Ux�>X�? ��`��l������?ZC5�ǀ-�X��������?��O;���m�yMTR
-��ϟ�ـ��APdC�?��h~Cn~����#*��@�K���8�qu�_��K��d�����{�_���WpVj�M�*���Z�f�1j�Ì�L.
-,�+o4�Zh`��R���ذ6�)%�Gy~�C���������2����`�ژ��c0`H�0�6��t��A3Pi&���ߝ�x��Qw����4��A`F���sf��s�3��,h����=,r�K�������+�½�"؇�U�(��b��A��Jw`W64���&4O����tOۼB��Bo`�v�{P������jv �@�P��#2��@��G��g�h��ݤ�qc�q��e �$ƹy��;	�_`|��2����$��&��;��������w�h6��<
-)�4H��w�n����c���x 
-d���t �	䂟���@8�����@�9P.���@1�(W��j�\��_T�f@�D4�6[�ç@5.nj�n����J-���QRX=gg#gg3���� ի� \u�F��/���Ѧ;?��5=g��i�}���7t�Md�I��Pt�W�)1A�)��7m�xK�w�oi�N��k�IR�I��q������8��H	��Wq�BpWS������s1�	?i��z�b�J�B�|�����A���Z[Ѕ��	>�� Un0�K�Gnj���]v�V�� U���cda�	X��P��P��P��P��P��P�+��`U�)X�k��`mp�}AP�1�
-
-�(����J&OA���3��*�@L�_⾖�+�5�l���_v��o��Fp�	��V���[	�G����^pr'(���w���(�C~�
-^ ����N�"�L����~0<f���,�(�
-��P!�*�B�`r�<*SBeQi���~ʖ{h��h+ WzX�%�
-��ո'#Tf�j��P]�f�=��_i��bnԝ&
-u{~ΚC����O�^���n/�V�O���{
-��C�(�[a���F=t������44���Q��^6$���dܣ�s|^����'�uH����I�Eh
-|��
-M{0>���3�fH�k�?�NTH���1�R���t�C�-p�3��"���c�&�ӡem�
-�u$����"l�G~�s�l(�C6�%
-�
-W�#�p%&�r,(����GY��*R��}mv�#��=��&�
-�dW�3k�"Y�/ݫ|A��_e�E�߼?n���"���mHOU�5�:�:X��F� �"o��������1�6�yǧ*�i�룯������0�O�x�9��������<�k�܀�F���w�Vd6}�$2���G�@��O���|De���Q�Ѝ�}�G=�&B���y�>���E����<՝>��*9@U4r��h�U��gTE#�S�|AU4�%�<��"�5�2�
-�8t��]����"���;d�
-j�ZA-;s�H���t����!��3G`ՙc���	Xs&:����b֝����3���p�V7ϐi���z�Y����?e�b���6���E������>��	�؀lP\b\@U�Ȓ��	�'1 ˊUL
-�&8��L�~q>�/K	0��]0���4�_Hp�Ҁp1��� �������0��Xf�9�#+�\^�`j��a�\#+1�&#�fd��l�/��ksA�W�`��X^�I?c���3�`2Ͷ��n�4��Q`�KL��)B<KMC&6g2��3V�{���	)�f��-���<�i@��Y�P���B�����u�X߻�
-\��#VRn��Y�zc]��j�o�+� ^�d6�"�����e�ڷG~��~��@�1(r�fMHS�Ҍ��P�$�j@3&�n����L)��|Ai
-�U
-�@B���3��<G��ʋ���(/�%��*�Zc,��-��gyP���L��TW�e4��I�w(�dK�[u������X@�^�{T_�eF��!��/Z&j �2P��L˱����Y�O�Hմ�'L�9��|��	ӛOh0�f�"H5>�E�z���G���d��3r��"\`����z\��Y7[��?f+�YeYskR5�6�X�ݚ\�Mu��f��J�e˭YA��ɲ��l͠�~Ų��WA���r��\��[m��5��v_���5O;��ް�T�M�2��2�Ò�Q��-Y5t��i9�)�g��m �!��jq���r�lQN��6�T�Oxbw����K�Z|�]����]��� �~˨�-�rH7-
-���X�-l���1�����;�&�+FeNLP�����A���_����1>(���	A��}HL���a1)([�������H�|P�}%�e��g�A���O�Ԡ����A�%���� S�,=��e���[*�f���f��Z� ����f��f�r�5'���@��ښT�k��]���� R��T�/a&u�0�j�
-�AJi��=��~����}O!n�ST�kqP��%A�8d-
-B�%�����IX��(D�-��NSS�M��r�Z1��� >���J3��J��r*
-Vi�Fc��i����[�i��SM4�����r�I��Bc)n��܄�H)�=-5 t����m�|F@�CY;�	wQ��$�#��N��_�H���P��,�r�{n����ܧ��<��e]x�b��<��x���a"ӣ
-�c<
-�O����A���؋}�S����=��=E�-�/D��Q�i�ǿ���<����@}��|���oWq�gl���e����}˼�-he�,>C|]?�#%�m	�Ccbd�B��c�a���b�i
-�i���i�>InT���m�B���g�a&f`�!`� �RlC��9@ 	�����WW6��z�Z���^�:����3���9���a[ף%���]��x���/�tջ�(�tKw=Y��e��*!�t	.OZ�f+�q�p��u�U�C���|����ŮW�J�ݤ�n�<�;P�kR�aMr>��X�_�E��n�%�����iR���iI>��gPY#�]���HW�ip����
-���/m�Ki�H�-�%���_�ꗪ�,�Ő�xQo��%��`�N�Fh��BK��|-T�_���
-�r(X����r��xd�J(�����+������j?,�n�/�ay������W�RA�U��	����jg��.��ױS�t�7��9�r-�r�����/��Wj�v���=��n-�ۭ�
-ޣ��R���A���ނ
-ޯ��t@;�I�-�S�tN�>ҤO5�M���6 �0k��l�,����b�[f�M��#��fl�-^�.���b62�%:��Nd5�-Hp�̶"��2ۆ��l;�
-�,����N,f:���4��vbS,����pH�����Y�6�eV赀�6 m(-~\�&�qx�ہ���;������b��~����Y�*f{��5kf�@M�B��^�����`����Ս�2�*��
-�
-\�[�� �����ie�����8T~G@���p?�#��G��G8*��8��/�ՂЗ�E����P��_u����UO(��W����e�Z��_�E�{�U��%t/��W������j���Wk�/�U�jq�>^��%������}��T-�
-��ES�ܪ��C1�ij��]S�Lij��k�@�5�� �����4�	��͚�$ �h��_�j��_���?A�ީ�O��5��Яwi��ЯA����M �z���~�OS�
-�z���������AM��ׇ4�?�_�ԿA�>����������1M�o���5��A�>��AU����?���Y�)~ZS��П�M�e����:�����jj
-ml��HE+ll�]V��4p�������9{���y,�H�3���<E*ٚ�.�)�4�-�+Lfg��x��^78�ξ�H����K�ٙ]�n�ig�ۣ��:)�޵�ΊTv��<�t�Y;�P���vV����`�6�;�w����z����ŵ�n�[	�6:�*p����}Y�zow�����)ҝ�E�������P�ݗL�{&8�4��f��+���ܯ68ٗ�ם�0���Ɏ���
-p����nS��/w�!��J[nx���R���b]��[�?8�b��w�ž�H?<�bP��?q�����.�
-)5l�����l��v<C������"
-��l|�
-{�����U����H�^c�`)B�uv����
-$���=D���f�Ԇl�" ���Bܜl�,��!� 9X�ȅٜg�gCr��PL^�M^�M^ɝ��1yE6��l�3!ٝ,����1��T�ob2Wl�T������.���Hb3����R}��U��%9�׿�w�,�����+���?�W�59�׿�Z_������89�׿�<u���|cxr���_(6��8�|�'�*kYty�b��_-�c|�'�Q5"j��x�)����T�_�j����AG����{�HR���ʮ���!���>��b#}�n������ԫ�W�/>�����F�v(�e�/ݹ�� �,s��k�Ot��Wsba�=[Xl��Xq[��8��J�)�֚ ʤNaIB��mMg�]#�(�+�eRbU ���� �����vIBO䥀9lc*s�F�P��H�er*z�Ő���Tt�+�Z�\������^�߹��/��<���A��9J���J �eSr���d��
-%G�ʆ�hQ��@*�-Ґ'��k~#'�:�ߤ0�~[�0����j�ě~-�X�r�k!���i�I�D=�/�R�wl�2�<�.`K���r��i9y
-{�v�NWTKb���q��*���\%�^[�T�c�<rQ�S�wF�L��w'���[�/!z��5B	�;:!��A�XH� �{L$;!��L5 ���^4��Ć ��(�|�����w�~@< �qA���)�� b��؆@tc ���@+��֎�Fg�[��
-tw�/�tc�ٝ7 �9`�}�'�9��]7 �n���8�ws��!�G��w�0��\�/����?�{��)�b�?��kެ{`D�ʤ�N9�Wo
-u���@��:�S�97*Ԇ�B]��h9���\���OZ����&+zl��Sd��6ڲ��dX-g�4��,�Y��8� �� ���p  覘G-��hȗֶBU�f��1��aT;hT����T�jN%F�lی�iϗA�E�T���l��Kjk[a@dh8�H��X��P�gE��s���۫冰��3ج�q ~پ��
-?� P&��5Ir�3�L�E��;��
-.�豫�:�I'�t���9?cU�5�y�kw� �ɩ�dZ*psN��
-+�~T�S:�/c�E����1rVaą�9�W3�{րr++��u�w����V?EE�o	���nOS�zB�0"k��Cu�rc��+� �h�4�x]�mm�� ��TͪlD��;��%8����� ���中r�ӄOv���i	0T��63c��I�K�f��:g��`�/�P��LD�ii0�h�l���<���`N���q�ِkOL�`����ӻm"b v}�� <;Z�h(� )�7�ꆟ`g��#,>Aa�p�s � ����� n*Y{c�އ�9���4�8L�8� 3,���\�I�i�F�Y9 �`�pr . ����� `�އ�yVx,6�|�@r,V�U�q��Zhy֣���G�o�)�7��惨n��Z�}u�{�kk���ǝ ������Iv���$[Bd�؄C��z��,Q�Z�����E4�����<ؑ�y�U�g�H�$|���=���㥉���Xr�h [Ls�6�%��\Z] ���V\��y�JL��@��, L���)<�30ЫH�{ԃ���]S=VLJ�ju�)��[�<�W�N���I��y�H�k.[���ԋ�_dh(e��2(��tTk"�i�i�����4��ʑ+�������k
-����T�wb�L�3�l*��.�ƻ,�1��o���Wz�,��$�qO9���)ƫh�AH?������\"��/<�`5�sX��2�;]�R=Ue+��V�z���e�R������s��.ģ$�Z/��
-i��WU����<{ ��_������l�tk�T����MW�(O�!?q�۸M�cؕ��h2W�����Z��ty�f�V!ga!�r�,���@�h���UJ��*jd��r~^�:��[v�r��Ğ ���
-�xr�Ff�&�1z���ā@u@� ��V�V �:Yv8]-�}��;1xUPN&�lS>�۔um4�mԘ��В.ђ��A��v|�1Qo+-��1Uy����=����6�>�OZ>���WۑW��]�<�+mmv�=i��6��޲ʻ˻>�)WbSn� V!��9 ���%ؘ�l� ^A��$ž/�z�}4��}ϙXQLK�P�Bwh�kq��}��x���x�A��1�^^\���] �W���3��8�1�����c&���
-�
-�rl�pޢ�ע���L�-
-���GD�"|������[D"�у7#�F�;m�!z���'0'过��@�TF�ɶ�b&�
-�ĳaܾ�T��i[�0'�ļ|Hv�d#����K�G��Od�w��k�8���$^�r��cu�Ƽґ��9 �[s�"��J9:�W��s��e9<�ƒ+e��}G*�m �J�p�  �������1���D�6�C��"���8�Ú|(�O��An��8	�n	j�	4p��\�S�pp\���xp����#��R���6s,�[�f�P𓫔I5�2� 3ĳ�8o�<���QÙ�G��$d ��`pN�1�!��[+���K��c^+���Z@���qp�^ZHۗ�O���^��`u�X��\ �t.�:ʺ�����b�QlI
-w�NS����9��n�� ��)*�+�'z
-�X��-F���|��Qp���)¢>k�Td���5�n�
-���E��(U����9�#-`g�h|�j�a���J���k�Rr��Q�c5@l���1�M�x-V7�f0�p�a�?]��>`�*��ϚUK*�d�ɑHsJN��D�S-�Q0��ƅ �º�(��N0=f�"�+�( �F+t�
-dv�R/�� ��<M��2���V�rb%#��"��@��v�B�B���2AWl���b��zWb"��(�*{��#�R���!�\`9]SH�;҉N�� �#��u	t׏��k�UgӰ���T�4���T	�Dc��$ӥ�iA�%M��<���ȍ��i=(�IN���M~����~�T��K�D�*2A���p����]k��.��.s��|�]�}��-�m��Y�}f��]�c1�G��������64���qiYݣ%�&�4A�2
-*d:m^�&��hK3��{���&��5���b��r"P�`�C��dVGɑZ��.�������,�'P��@
-�V�8��a��ĆQ5��	�у�털A�<`�k��M0I�p1S0"v(��� &P�`��Z=V�N���Mc�0�"3:g7�G�3�}"��ѣ�&s+�wS���QPI��X��*5#��c.�dϨ����G�j¹��)=����eln���£M$��z8�M�d��t
-�W�,���<vU�6�|�Ï���g��o��� R�z�@�҂yYDDv'g�088����J#g#��&���ȧL�S��u4K���C�[���\q��14�l��8+��xR~��O2 K�=0�gO0D�
-��U�q=�V�t4Ek�iWj�#��,/"��qn��*�渑��T)n�hd\�|�R�h�:��K��mmvŎ9�Ε�k�
-�ǝQV^���K��X�妽h�uŴ-
-���"%n�)���w�m�UHU��-������$ ��V�.�lw ��+.��q����q'D�ˋ���.=��:����E7(�͋CGe#�)�7�\v�s�k��ﵵA�O�9nK���pfp0�Ȫ���^�p=���.ZR�]�&Q�A��7� vEj�hop��tݍ��U)i<����j�Tr��T�6��J���m\�*+or��r/v��RH���d:�I��Lz�A�N��}��8����|�\@Q�0���L��q�Fٗy�.ȟTg(�'mDHu/Q$����ך���TiXa���Cs䯇|�d�=�ݘ�z}4�~���0O䗖Q�P\�tp8����4��#�ƀ/��`��kG0��(;��G�,���o�\��H��?a��j�%���-������l�ͱ�
-sJ�X��|p5:��c�G�|�ʤԅ�t�5-�_���L4�0� ����Eܸ*ԜT<Ϛ��H�QM5�H{�H��Y���"f缸
-�ZA
-�}i�PoMX{�n��{؆��+�F�i�-n�t�^[[
-tBO-�J�Q���=��}*U��O�J�����ƁW��sE��]��0�
-��h��U��5�!�4�8���U>
-��	�;C��0�<���*/F`�wA�� �
-R��x�QrP�G���2	5�S��6���@�N���@��{�0�?���D�E���,�73�%fﲁ��wi7�$��d��*�G�ҡ��T�޼���D��Rzd�"�=�g��@���E7c�w���4�Ûd���7������@���r��,U���+q�qu�N�b 5�j��t��T���=�`�4RyK��w��sR.�{y���i��V*��(�R�ͩ��hEN+2��������2�r����M�e��N�
-���3��a7Y*{n�N��<(s�a�� �X�@:7�oL�S#'����9�6�n���u+'�Bt���$�?��.B���Od����k��3����'�����,��]fs3���Jl����
-���� Мk��M�\oH��p 7� &�6j"a&��� 'd��k�K�*[r���m�32^�K%�Z\���%�lN����
-�'�U�~�D�
-�u��+�u
-t�;(��R����^���bl�O�*[�R�fh$$�b�d��A��K>o��G�b3��AFT,3�6��XbU��f0/���I���m�?��t�Z[۵��mm���z��=��ik{���t-�����x��	���� �*E�~�o��.�2�b�h��ɧ%�Su�S����0�tى��ke4I��*�@<����c|��oZ�ӛI��fX����#�:4l���i^���ڳJ�YeË�kI��}S�-�D6q!Tkʤ�F������L��32
-�08� !�,F/�ڲ��!02H�Y1z�A�ݦrdZ���l����~Зܚ+�ځ����=Y�]���s�2�������ؾ,�}v�7X%n���
-�w#�|.[���d�ߌI�l�o6�o�2��k�#�h���ͧ+�+o��.�n���d���^�D�Jwܛ�Rx�NnLj7K�?LS�n;�X)^s���l��ഋ��kη�ou���4���CN
-� k�m����Sk�V��9�fpN�.�5'�M�i������v���jǗs�ެ�� ����ps�.���sDƜ����X�di4%�Cj�OA����~g�����P�y�4�Nw��N����	7g���#��5���b�Y�KֶZ��kid�`{�p��`x�M���_����bq��W]?l��Pc}�u]��,9���62�B��@�K��l����L��E���rlzo<P�F�ἀ�O��N��6"��լ{��5�� (A݄�4��l4L�{�FÆ�}�����[�;XQ����$�� ޕ�ł�S2��3��s��TT��bj� �+��)z���/�&; y��}�.�P:٫�p�+ (v)0۬��9�ጛ����-�Zx}#��0\?n�*&��}�p'ȸ�/� ���p�D��
-p��Si���y�;:+X������
-��� )�����&�q:�[t$h�>/������U�2��6FN�!n����������S�?�`?�$�����w�RT: ��Dan_Ɍ����� �4�����?�wD��E����P�#�J73i�uIE�٫�=8y�D�G3�����i�.�T�?�C;�J�� �LnPU` ��������X[bI~���2�y!Yt�]�?A[$�Fʽ��;�2 @Q]PT���?PfFw�ȍ��1_7��6�6�-��Ȋ 
-�OI�N�!Ԫ㺯𫹯���fv�y��y���5�����i|1��OǦ��#H��<��a.�(���B܉W��*�<s�}���o��Ғ��2���e�u
-.d˓o���N��=<� ���l�<��GqWimi��@�ι`k�Ҿ8h�/�)B����N���`_��S��Vϟ������E��j;B�bMA�+�=_����M����YC�Lxxf$�(���b�K���ٍ��0'��S�����1�����)�2���(��d]������%{��v�)ڞC�Y'r@��.��Wwo�l
-�@����<Xc#�R��" ��3ڣ@fA$ �i��t��D�1�4Z�C�[��&��bI���c��� �`F�O�
-����$��X��"z��\�)�m�Z��P����4D��n
-���A��{���:��^v�t����H�ǝ��rr]q$�?A�{]D����R�^�����/�˱�.wbc�\Y�'���H���|	�)ց�0���1���j�/���x�u�Ou��i���F����[� ��^�2ӊr��>�6�uCtJ�3n�>	R�J���?�[��5����#b�f����1��*���6����o[[U[[][�3xT���0Fk��
-# |M���\��������;�9�1�����1O��[]M�q�B�����������6,��}��4��鑞P�Ɔkg��J���8`��)�WU�Qd�AN���\\?Oh]�d$�x=H�*�K����t���^v��J�m�^@Q��tA�ͅ�s�nx�M���rEuE��0�&׶`H\B����V))����U6����1�z�a�?�W��M�����24M�?�Wyo6rM���e��0�\��c���hɏ�J\�Yf�8���;H{?�☣� 7@�-^yl-,�XƸ�������Io�I~g~�z���7��2��{w�r�������Uv410�p�o�چ��n#]����!h���Ia�FHi�
-����٘.B���E��T4H���D�6zԑ�(d�=x��!"�u0lZX�Ď;2HкvM-;�HeY�7:6]�"7�-7fYD�t��&�I�	��}��#�l<�����07u(�&���i��td��,̅���p}a��n����e9�n����Ď���(�p=њO�9��!Ό#�;���EI.����
-��c�9�%Tc=t"�]��#J��[.����؆ϧ\�N"n�a���4�ҍ��{Å�]QK�;������hE�s�ޠ7A��:�T�[��|�
-e�q0��ci�5��f����X닎�e_%�#3�L�����:0<��b�C_I�=�-Aq�_z�J�؛��jE�*�g��Y�*��
-ƕ~� ����u�A2M
-��N����IJ�t�>&2��5'=$G�u��b�1�������6��i$-�S}Ȏ*�������	�p�b> p��(9�ˍ��c��
-�o��)��	������I��w�ֻ��r�H-�.R2�Ha~6N7o8p�ɫ�]iH�Ψz�g����~��|ݏ��:�x���G�#n�-�uX���D��,0���6�~������fw��PK��k���LӜPO�U����0٦�q�e���[��u�Rz��4c��2�Z�H��{n�g�l��^��=X\/��'���/v�Vr��гC�U"�O�(hp�GP7jN��p�����:�����c����9�
-�=�P�	
-%b�Ԃ��V�ud���f�g��d��� �>iW
-D�
-�V8��* =Ł3T�� �X�n��L��E�xn��L���F���"���+�轢
-�lV*zXa�f���)š����6h�c'(k��Ct�ɑ.�+�ڇG����TCF�4N�+��y���U��jQ�i��Kͺ�wL��q�M�+��§��ږ�/��ӹ���%���>�8A�k[3/z�F[tn*ն�I�⤃��v�f��LlgP'���뼍��El�M����W�m��c)A��{
-o���s��'8h	K�c�
-U�o1)h�1J�J�'�b��+G��</�4)9�K���057��DQ=1�~Ӆ+T�.��t7	`����"4~D�ۄf���o��|��_ ��sN�L�Ʌ�T�x[�EE5��{^�M��b#)zg�R�����Z'���a�nF��δe1זF
-v�^�J~$E�2���)�z6.;�����=0;U�]�ua������j$��E]��q@�Ӡ���`R�&$>vY�j�.�HQ����;�la�w�����._�pmK�^)��mqh<���41�*	�-��C����u�2l�y6C_�K\F�݋��(��骦�k}�4D��.ha��q�K,.�$����@�
-fCo�@Y�lM��Fq�3a��:��s�Ճ���z@Q56��ޢ��$�6M�F�ZTcˤn����� \'�� ���vE����G+١�F%�Fb�8g��(�"��Tֆ߻KS	���US�i�����z�Q��a����o*���.�웼s٢bc.[T�sʪe��b�6Fd����
-��w�b(�D}֋���4|�79E��y�s�Y>�T1��t�83�tZ������H5���Nչ�.���:��Q��td�&<�ւ}��4��1{�W�������HA���HIm��Vs���9��g���X�\gfs�^U��+N�E����bn�|2x���M�ݏ�b�E���aI�:XF�W%��=O��l5�>�8�;��.��7��$���g��B&�W�x���c��[QO�׸���Tc��U�go��(��З=8��g��`�A�a�%��=Ů����#|��1����+��ѹ��Τp/�K\	�u�U��D����Zt��E����U�����m2�VTL����vE�b
-EԶ�*����?�t���;�R+�w��û3:��xU�G�qA/"khj������{�S�4�JD ���6%�z�v���e(�*r�"�)|�(�͆��8�i?P4tz��!��#{-{lD��o�Q��*NR�Y�k�0�${R����px�k�B�����o��ߡ�
-��=���(�txdw<@�c��J^��*�m�G�*%��{�JM%���o�4�٦i�6Mk�ZƆ���c���=F�c�l?�^�R͂F��M�9�+����^�S����������nF��HN�Gu�)}7�w�>����=7&?� �W�}��!��c�K��O��[���-C��)��C���z�Z��Ɠ��V�>�w�
-�a���O��1��o���Q���
-�;z���vho��Rl�@�J1��AՎO�7�Ì�����ٯ�� �^U���xiY*�}ck:#�[+澊��sZ�P0�fIȘ-�4q[֞5nC�U�ٛB�f��b�I#��KU[bN=#@��f;e�91���]\E���REc�e|"�,�{����<v�� +qɂ�H��(�}�	���>=�S��{��@�� @f
-���������3�H�Q���V�+��=�T&AM��f�>�xB�݊����ˤl�I���x�z�L�hf:e�����J��������*M�P�:C}
-YJ&;��a�JX^�9��\<��{��CD��ܕ{O&1/���v�|�`DC)9_�6��c�����6љ�������ָ���4�ұQ.�IM���C�ޞ���|`���b�4�&[o���l�����2��Dq���-�Y��Y��Ӄ��| �\!�z�>y@���*�U��
-�-rƆ[�������4H�b���3�����>k�O�+��WQ��r>x߾���n�]�s$R���!]�<�"��[M���^��NB��cK�`7c��Cw�~��Ql��ef/K��C�p��}�p&�:!4���)���IX��|qmI�9�ٌo�E�C��"�J�+�g�c2����|+��6�V`���V`���[�}J`u6���@`��
-~�	���k�>��ݣ�Ot��O�G�hy�hA�h�>��d���ޕ��?�	$�soŕ�fdFƒR
-m�$�R�%�
-�.W�Uu��ڮn���U�k��͔�IwNvOUW��ᛙ�7#�`lc��#�c��x�`�1�Hb1�j6�Y��9����B�LM�}��q�˹˹��{��F��df�D^^�G~�T�(K��h��!��c)v#Ŗ'�+��hEA����)�r
-�Wd�Wg�7Q��D���>�-���)�� �ƞ�&�@���{H|�i��GBƇ�����'������B��B���~Z���
-����t����cW���m�}��]�IJIp�=gi���L����+���>痥��{�w�4�QY�|��y��>���<Q�ON����{B�D��~��N�G���`)(�)lh����4 ����+���YִM�y-��iY*1KM�g��m욬���1�,�r]f�z�f�|��RĹ�K���<��_���� ����/(��!�K�:ڝX�o��
-_GX��p��|��s���g�`,����+|��>����5��=YD��@�E�w��Y���fT)�#J�#HԪx}�?��3Z�#�����e�izW��5�-n��x)?����ם�_wV��W�oE��n��ݝ�6��n����Cm��O��1%7+N`V������V{jO�R�zS�'r	N#���O#��9�/��K <�r��SX���`bɠaM���/lK5�Oig6�� �%,�pN���c����9�i"R�E:I���3��U���,W�W�{B�6��=�p
-
-Q�G��E.���ɣj�e�*��M���2��ܞ_���j��Uc,r|�s��V�`N?V�KЕ~V.�8�o��71�T��ߞ��]�O��� ��3"���&��*.��#�.���on8,��%�f'����3J�۝d^�VO�V�]��4:c�;Г6�9	[{>�T>�<���95��*%�UQC�EN���/��|�����~��t.�v2�.�vr~�î����NEڥ.\��eyo�k������D�sozn�M�=�v|��{5W�����{1;�^�G�+�J�G�����\i����7h7	ul"�%B�r�[L��nI� =��NS�
-l8�"�_RYL��V5��
-� Z�}��O��es��z@6دe����� 
-�:#ڦ⢟5{	n�5uo�`6-�E_xmS��m�5��p�'٦"��p=��4�*��T��P���4�ڏ���t A9h�tP��5E�
-
-W�Ҳ�P�����}�ö-[|�t������hs��?f�?�;J�e�k�Т%C�׻-5d�B�0s
-Wr�wg)�'��ݖ��v�K�f�v$���)����y1�GB���e��r�؋�>�3�X*�~�7�	��K5�	J-k��������7��3��jWx����Qײ��W����{��t��{�����s���O�	��\�CaǭT�e�+ڢP�IQ�8n?��C����Ƀ�)��n���-�������u~%f9Yot���n�@����:��Nh����2U��u�a/�0���������v&���u����s��l`Ӽ0� /�� P��<�>�i@���O9�L�i��wl��1Ұ�;��>���|�w�V�b��h8A�1�-���-UP��V�n�V
-2yLI
-Ϯ����z͢�ة�R�O��r�����[�18&-�2����
-��T�;��!d�M�'��R[-Y�k�#&{�mm�4���J��R8�U��ea���#�L>UJ��T�RϜ���%O�{��
-6��K�l�`�T��i���Z�OXY�&��&F������5�X/�������éFi��vd�S�t�+����to��vJ6�
-n%��"�v'����!W�@� %�V�5��"h�j���NS�.���(Y�\�*���U�8�t�/ʏ�]������~�SB���#���l,^E,:����}��mL���*�Z�����
-��*��x��A�B 4�)):pM:�`]ztExV@ (e?t� E����V��u�h���]���{��EC�����]����
-�D[��צz*�^��a�����V/��VٜȽ
-������ѩ�h�_���6�>jii�����4�4A�䨧sl*ѭ��'X��Z)�y�P����BQ�!���r,^�pl=�`�:,B�x�.����;��;����~&����~��GwN���2��d�SƐ(�
-���ē�u��7�	Z	I�y?�'6��B�6�,���m��FhZp���}F�5�ܠ4�e���o(X�t����PU�6�oEO�R�-�.��ׂ9E �8��<6�z�00T��;�¤mc|1h{�](���9'/�*:�|�E|@�n�Q�5��ߣ�&"�f{E��Y��kw��k*`U�F��
-��P�T~�O�V���ǋ?O�k���Uv��h��\��vc����*"V�g�h{��{� �)�}����Jq�^�Rٕvn�
-���)��+*.�Qe2�B�{����������G�#{��a��s�-�A�������L��M	�lŌ
-z9�dc������!��[�\�ߊ�)��+?Ll��p�`�ֆ˟�_���ʇEyE���3̎���F}�EM��;�A�8ȵ�|�M��M��̪"�Qu��4���h�j�����������$=U�il
-��?��B��q�1j�Z���A���c�BpcZ5V\�R�ܰ97|g�"�-�O+�d3K��*@	�yw�
-*���n��P� b�o*��f�����������	�a�àI3��겛��9	��񂦒j��5�x�s�<�eoi�ї�YY�(����q-^H8P'F�Z*�A��aH �)��$�ò���������)̢�j\��&��\i\�ĮJ�2�h���UI���i nLYL���I_¹8�.�<MՔg��J7�,��⤚j�w�)� �9��qs�0�^%�T���o?�b2	y�H�ECglW��Q�K�_)����5hgh;^��vGy�C�t3]�;�~�΁h��t�:�� 	b���e�ĝ�ȲY.��!d*�I]�J�YO����g,�ŪD�c���X�.�uL�$��V��^r{�EXYN3m�?��Cz��}:�Ӯ�ږ�����X1`�6
-Qh���G<��O��H������A����8�A����GK�ޜ��eF.��ʏM�ym�j�2�TD��$sr�y
-��SB�S�{���
-��:sZȊM9��ؔ���PG	OY���f��1��+m\�	�.j���A���b��ѥ�����"�O�^<9�p}���+&_������A���Tjl˶
-�Aʣ�i �-h'���@�}�� >FC�W�,v�[+��	�,a�]�!�/�8���"�g����m�����w����]��[��S���Lf���5
-.���f��eo�F�iF��}��Pd��v\�/��b`�)���6ڶo�;/��m(�*����f[��B�-M�r9
-hu�p�ښ}�����(;bg�e�:�����2���!#GS��=4��@
-k;�t�0���Ô��.5����	[D�8��Z��ǃ2K���.%�	#J��嶛��5�M�s����f&�o��+7r���!�@4\�
-
-׳���#�t��-�1�M��,tJ�~fl�٭z�Ҍ�u�,���
-r\���_0\q0���"�u@|�S����Έ��~��l�i�/�����]��}חӒB�������w_�/O��� NƏ�`D@m����#
-��{���Z��At�̎ڡ�U\������p饂�s?�{�c3���і�q�p���(5DTH�A] IV�R[�*��'T?��̓���m���=#{p���V�Zj���cM;�jAq5}=�5�i�̕<��
-3�<��J�W�??�ׂ�$=3���Pc3���A��U�j\�'%`{/��.�?�N�p�p��w��\�'E��\(����0v�7�L�,]��S��U#�יb�]Kd=�)�鵿!�!^��<'���C{#l�Ȏ?���|�Yn
-ߎ(�2�w==�W{^�ڳ�j���3���o{z~��M�5���Wc�WM�d+zI�h�W���5�'��؎alg����܀m� � D��:�Q6��*� N�{t��zz��������'U��$���x��^0�Csr��|#AY#Þ����N�;%�a8�fw��q���Y1��<�j}qyvz6(1�q$��:���!;��Ky����f�x�
-�Xo/ӿ{T�����˭�
-l�fĚ�]).a�k�"�]�k	ޮ�&��}$/��Z7���vŭ�jK��v���Px�֜z����#W��&^�w��ۡ����O���%�H�o��}�í�'h���8V��}{ZU��&�-��+ĩ��qW��cQ�pXfQ�z[Q"܉w����3�"�&��iD\��3�$�x�Ù�ꕤ��b�ַ���N#V:j�	hj��3���g�����|��
-��k��
-�C֨d%D�yxPpW�k���x-��0���șv$���x-�>����K�,:�`�v0�Šv¨�5����_��#��rx9���QD�'o.,́=�e��P�}�p�s �b��[��Z�g�=ò���2�]T����,�Ǆ�p\�W��_x�{D�S����YA�*XtJVA�n�3{?l%>G?K�g�������8C���|��6_l��y���b��N��y����A�l����5��u��<�����l8����Iz��G��҉�v�	/ޓ������(a����j|Q�Z���&��\
-n��}�����3�fw�ʚ�3.U������X���}ɟ��wy_j�9Mb'H�}:Qj��n�:A��u�`�W�P�#Z)o��l9��,�gnŚ��*:�E��z/�<��]��Ng��-w�&�������~������ ��M����m��!��p�1� A�|�����x͉; C���y�6{���ȼ${%,M�
-ke�-pf�W�3�����\)<r�׆tS�g��n�|h�wx�������i;�9� sJ��7���_(��K��w�x��x��3E]V�+��X���)E��)ER�^�)�����'�R��"	�M�qb��Ǻ|�ϰ��uL���ϱG��2���	�K�G�Xw��?д-ܰ-�i�����י;q���gi�Pەjj��u
-s5�P�ǳ^������IF���� �����*�k��T������a���b�{�7m�|A�B�W�P$������?����z���)��Z���þ_Dh\_l�ՍT�9(�Sv�Iy�wf�"!���'�~[_/������'���صbI: ��8��[���㯨��a�%�l�ǻ�Al5������hܴ�&�,�qoqާVTv���w�O
-��-�+�ٵ?������lJ�ťB-LI|�t���G�'X���ă�a/�T>sm�OxGue+�q*��9ߢ�k+�������3
-G� ���]�4>q��������l�,��Y�B�m';aq�j&�Yvb�'d��f09`Y�<���8�������+�(>�s�8oQ}RQрT�4�^�pj�����i��)����?��>!�g(r�d~)gé�B�\8e�U����c^��|E OJ�G����R65�dŘSi���J�:om���[[n������C�N;%����K�甘Q�(�:�8�.��bQ�(�]o�C`�mUK����X�\5�(M�qE���1�k|�U�d�R���ޔj\V�ԇ�
-LU���ê4W�l_���Js
-�_i~D_�$s#粉�U�3�'�q���L �%�S�:Vin��)��B���SZ��!�Jj=D2���)����>U2�Q��$s�H���I�N��`E]�4w#�ഗ벏�.���5�~
-��>]2�;D_3$��$?��?���Ǹ��r�@_�̓�q�~����2[e��Ǹ*�)2>K�'��s�h�d���=�W�_Q�K�y��&T�_s��DE.S����F {U�_Ou��l� �����r���#��F����)U�8zL�2�ǌ*�!�d$u��7���S�~�g>��@�����%��F�}��0��<�-��)�M2_@.�"�$�y/��Ѹ/�1��1߆��FgR�Z��0���3���������f�NQg�L&���_���4;�	�ͦ�q8e���~�k�	{ P��s��Tj0<e�;:�_��:���3�c����Qg��mv�s�g�y,H�N���6 ����P�v�qr�8߻��R��8| z}������rVio#�C��W�:W:���}>ާE���	�w�Mr�D�dN�8�=KZ߱�Ԙ�Z
-��`�Q�	�d߾ɾ]�S�v�3"��̐�"R�p�D��<Et7�X�5��Ub��1��CSε��e�(��l���9e�\�D;��-�.nb��7�f&��ÿ��#���NW�-/��[��"4�۸f����N��������dq���g^(	��<��ds��6��x���gI�}T�9���bs.=�+1�E��c~$��bo��"�>�9�06�����deɏr�_K~��!�F_�ͭ�>�x�
-,���q-��� ���ſ���7~�Î�G��ƥ
-�\+��>��%�?���Jo;Ԫ;J|�F�Vg�j|���G�� ��@m��4�@����bk���pFC
-�*cV���`��
-c�`cb�q`�1���0&W/�o�1��XTa̮0�T�{+�yƾJcz�1��h't�*�W�*�G���Ƙ*c
-�pM���;X��r�s�H:��������N��$WG�}%G{z`	
-�O���'DڤN���J��	7�ok�R�w��bV�WK�
-��)���Pw	�Ěۓ�q�K������D�?���f���Y�0����f�ۘ��q@A�cL8�X��3��
-��fD�J�2y/t��Ws�@M�W �f=�k�I�W���pLd8�����勵�DW�y
-gZ�V �2�O�
-5������m(f�&+~��p����6h�4�hL���+1�(gŁ���)�Q�6�OY�`��I�I��!i�2���Rk�L��+Z��vZY�w#�2�zaI~��v	-���"�u��TJѠ�	bF���l9�����狚G���ѯ����T�Q���m<:�m�v,��iM��� ;��9�_�nAss ) �c�������5Z�MJK5~�A���R����I_�D�ָMC��2� ��� �m��J}i�rZ()k^�_�� ݙj)�b��i�-�J'�{Gg��!pt�>Ѳ�4���avuC3��Ɗ��������
-�g��kB9�4�g�m�.[�$�S�~m"L��愖)�}6Bwiv`�-G�sk��6�����b'����h[i�S���"�jq0��uwA$􎲳��쨥��ZG<;�������rrn�y^�8�?9/�<?t�f͜�i�9+���F�
-7X\�6,�/4�t(��������qɯ4����O�k-c�	�Á�-��=��M�֣����|	���K dr � ��p �9� �b ������>�"��yX1����A)���=�N�8@��L�ix5�F�,�"�����ʇ��[q��4��`�V�~��saW
-���/����T8�G)�j�_BU,Q��\ၢ��-qI�������K@T��j�\�h7�(c���E�a+��]0̎VM�wrj֞��R�{�����Þ���BOC�R��N��) �Q &N	����eQ�_�r�F��4�t�q��ö��~����8D@&}3������N��9�3���.�l=�D�V��&�.������S����oU���:���ie:���[�)��G��v����s}Ň������sM96��<~��<���;�3�<ϸ�<����<��'W�U�W_$�#l�p��(�nW��H�"�����Mg �1;Z��O�aNXkw�>R~�������a[���B�q �8�g��DY�^��+�����b��\��p�X�g'4���f��y��ب؎3�œ�
-�bL;��l;���G���i[5ШQ�H�s����F�(�CQ�8d�D�'W�mM/�*���4��/��-O.���{��Bc7�5���)���0v��Pw��d�_i�g�@��Ҩ�����vr~�}gx�1����"�Ú����lc����0*B}����%����߁|& ��F� ��0yfJ���^��~� pQ�x.��SU�TMɀO������ݞ=h)�e�����4�n���v5�޸p��L����$����5.�����[E�Q��tl^(C��s���[�4�ײFs��<� � ������&Pʙ�Y�50Â63�� #�D�vL�~��	�݄�_$U��I���
-+Ӽ�6S50�m㩖�����v��/YK�(3��S��-��.�ʑ��}�6->y�W��W�[~9RM��uӿ��*��LV��UM��I:��I�P�bv�[��ᜣ��sȶ��LϱV�~����
-o��S\.���{BO,	���܀��m��q��gX�U�G�$Q��
-�
-�Cݥ����uE��1|[���m���sQ�*��7.g�QA��D���i��'u̫4^��#�I�Z�zY���Waw:M�tĊ�HȌ�(��q�zz@5��1NGӦhC�K���Sǎ)���ўԳ\�r��I=��S���Ɲ��G�0���Yf�g�L��LF�$����K+�m4���������}���$����O����L�U�/a]eR;
-m��c��@W5�יT��E�>��t4��q��~�
-�#�Ń�)A�۝1���`�+�J��ae�N�\����F�/��*�BT��3��;�6�vީ�f�}ViµU�;�J5��T�T�>v� qq [HDպ]U�ɷV͝ʩ�;*�:��?�хA *�b��׭�Z�z�q
-@���г$�l�Ϲ�}�t�s���'
-��˲O��t�f���|��sh��8Nr���˘��W����+�
-5�
-y�������ϙ�D#��읋�:�ܵ�b��M�A���Si�T<-5����=XxN,�S����ZɇUz��ā����w"8��a���M"xH�tڂ�/�W)˿HO�%�n�0>�]^I���w��ƌ ��o�� ��hm�@��yȋtܼ��e���m�!������e���m�!w���N�+ʎ���^�U��M�$DDWI�Uט��N[�� �\����y�27�2b�Q���-��
-]�BW\O��l�K�B��(t��[�i.t	
-]��2���W�����W��k������Ձ���/���l;y)�~�g	_�-�r'��E���k�e�|���X��jtW���͞��:�������U�}3K�2��	����y��[z�ҷu��2l
-����o������Y�Q�W�Z��hv���>#����yq�V��(�_�;a�G�n�f��v[����V�F/�w����mlF/[�٣���Ϧ-��_<���y�9P��g�==�mTw\����p�/����ʌ]ƚa���n����wu��c4n��i'N��X5-�Z&�̦�9�u\�\B\��6q\�]ً�Q�\�._�]ׄ��Rr
-5o�z̍��]�b���T�OkJ�&'|S(�	5:�]"�Ȳ@�V�)���Xc��*,C �����e����OBD͟�b��蹐Ǥ�O�O�´W$CC:C�u�"%�yYx�����^���w8m�x��]�w3�2�s�����+��V9�k4N*�d�ugj=�n��=��0����!dQ����afh�N�]�t&�7�1�������j	��*�n��ǏR��sH.�p[<l��0�����F����D��H�{S��aq9v�
-,���]r�+��$��+���q��5�R�o �M蝋�Xp|	��������%��Ul��e.'�0��)6�`{��b�g���4�~��D/E<Fk��cu8.��j؟��Ъ(jM������#v�H.e��@�z�����
-���y$���ǘ�&�K��<�( 0�����_Q���<�L�/��A`Cnp*v@��L���i�	�?��,7����������GC*0��րLӁvKM�h
-�5n����;��	�[o��̓uB(�����.�&`�(��x���F�7�rs�7��u �q��ĕ�J��8�Y���Z���~�ٹ
-oi����l\2RM\�<G�F�k�Ո�i�b$z"��`���ӂ��:s�T����'2j������������ ����l՛-5�WP�?a�	W�ز�zM̫�55�GM��.k�Uj�k��PM�;��f�8Y���m�m+g��r3��)����jz�X?�Ǆ\��ú���Ds�+NZ�!��%�T>T�U�"�,wT��G����X�j=v�wl��H�ET�+-����1�uL�pym��a�S"�'�R��0I/�ϓ������i>L�;��[j�����V�tYL]!�Ua)�<v'u�`��7�3�n%-���w*;J���ӊ�)Q���q�ɫY�t>��5X��}ˆu8�\�|E�s-O�Ui�U@ͨ�]�oU����\�a+I�ߎ���Rb���E�r!�������Z8��F��3iM<Z�S#rEJ�̹������åՌ�f�T�Q���no,8���V���.T%P)�l�h�fP=���3�W�P��_ʍdv^Ѵ3d�Ɲ!lΟ��e��~8T�vY:�@:�S�� ~��F�kJ�0�։�Cޖ�wg�3��e+�����Q��P���!�G5��×�:5�8^$��ԗ�5Zw�F�"��]<�]��r��8%�abK��+��� 5Z5� q���� ����=R� /��8����/��l�_ȁ�j�5���PA�Uq�V�s3^WA��m��D������'#�`�P�d�����2�\Ɠ� @<��G��Hh�x�p�򏢑D����
-=�
-qM�1"Z�/���+�F�OEoTD�ۦ���k��~�抲x?lc��(��+6A|����e��Ć$�ľef9��4ʘ�}�1�0X��
-��L=�ߪ��۪׹����<��ny.�Mz>�=x�#sVK��[�sk '�[�㟪qq��#{Zoz�FR�Se2�`=��}H�2^��j�2^��j>2�$������C͇B���C���!c���aS&dZ����DۘO����X�`BM*�%��_=�l
-���K�I��U�����'cV.��	kh�_��f�U��cg=ڎ�F�cw�sj4��8LC��PlwU�py�Dy*����ib�]P[�Z�x�uL��������
-�Ǝ��+:���X���|b[��rW�|�Ԉ_'�ĕ�9��}�M�AN%�".�ة�S�إ���e�nN痽�9����n�ȡ����v�?eT�"�PF�'�-�#���*�L��WǼ��f�f�]W��FhtV
-��4�!�����n�� Z��@��@; �r� u��vhq�N -q}�W�>�R7�. -����n�� z5h7�V��� he� �r��ky@{��1A��4�+�	��^��9tMv����e`�P�_�@2��`��o�����p��V�2�v����^����A��	���7�����«o�$.��>
-G?.��,5��45llG����h�_�m>jd�b@
-\��~>dl���C�B���|e����(/�G���E�j5v/z�8�7����럅5�k�?�6<��H�j|2^��*�|1d,��j�:d�: �5�,���;���R@2�M��n�\��|�K�1�<�g�X�[f�(W�������/���R��r(z9�1/�
-�Clk}X�(�
-?_�猞��I~��,݊˩�w��9���9�%�Sڥ����-�0��ع% �������Q���J%.�->q����$^�1>f&�����vqy�|R4�|�ڄp�*%�!W�{�����F@��i����Fz .�~`b��ѧ�Ң����"V�DdB�XT]�%��o*qR��8d���  ͞ [������:�g�ɭY���}N-����=:�}F�T�t�#��w���}b�lC֡+�w���ր���� r�RȖ�%��]"��=`�8"�wPH+�E�Kp��5�@(�;|0
-�{F��í.|�/#ЏP�C�q5�/��w�!e��B1z�5=4U��G3��p�mŽ�7$*�qI,zg����� ��� ^8�B �;�P��	�j��r*����{æ䯲$�1?(�o5����%RƤb_���D�2�xs���DjhR�T�&��>¼��<���0L�U���*Fi����[��Z���gb��[�Oh�Baܿ
-��ޑ0�w$���2N��KÕ�bJZ�P��g5����5X�J��j	GE�8(K�j�XB�K�u,���c��J�l[ǘ:������c����1b��ٶ:$�1u���5��I�tO�eg}�L/���Z���&L��
-��J�|��_��+0�0��?��?86�3������h���	Q܄�0U�5!:&�3������.�c�K{�8E��oߖA���4�~F���n�G'`��L�DHl)��\Ǌ�Y�ɀ���@�Ƴ�o/M��iyM�)EHLؕ��`�?k���&l���z�E�衟����۸�c=h/�u��
-&]3_�� �TBp{�!X3ċr��l*>��`x�O��a���Elӆ�>:�m�Z�/�:m;
-�u�wټH��L(�5>&Dq~+�9Z/,�Ԛ>Z�t�[�ڢ��7\��7����_�e�^x~jz����.��)�_7 q?7�9�Ѱi
-g��Kݟ�6�8�b�8���������w&RoO*ޙ�+��3�x�lǘe�����l�%�U�cX时����_�5��y �r�@�ω�_�@�'��p�D����7ѽ"�	u�\���������t��fV��}�`fe� @�nY���� �GN����W���ESq��Kx�Od����G�O�{�����=�g֞�T�S��Z�2}>�:�Ew駘_�ʡR�X	��F�T)�P�E�!i�j*���QF������<Oqm���D�ؤ���u���I�u �Wu4�2�D\������*�V��|�<'|-�r�CȾ��}>>FT���і�����)�ZCT�����	ڔ�N��^YV\��ސ8/�ې�~�&����C�5*z�B����>e�K'GGkW�1-�k�r#a��U	��Ej�q�X�^�/J�Wb�}�D�&��e�M�g&��*��`��jky��Rj� ��0�����Z�e��CƟS�!��!~
-E0�#��]&n��2�BH�/T��X��^(�D�1@��@g�g&7����N}"��Sq����T�cۀ������	0��Ú���XP��\���E� �����s����[��w�&F��~�EG�&8N8�塊u#�����iFY��TZ�I��2[z�u,��|�	�L�_�
-���V���=L1��!�C�n���7(�D�ZGc��"�#:�X5�D���V�%�Q�VPِ(���գ�����Ч�D�j*%�h:U}�j<�"J����u��;�
-�2N1�W8UGbC1MRS�b��G�1=F��4�i��1���j�7k�G�?�Z���`����Z��(��8U� zP��b���~U����!�y'Uo}��]��*<�<b�
-�0_�����x�DC��Aq�Y�	�G-S�@LC�ʒ�5H�x�O=dJ�*(�Em�۪���d~�Ɖ%����q[��j�U���=�GĲB��X+ɨ�M�x^pc�i��O��7v�'x|�~��|�1o8��M鯶�Tm�}I�6��$!�R����o��[����3yP��
-��P��D@��0>��gF�?&�"��Q����<�khW�P�և�*�:�Lh��u�Ӻm,�cQ�UZ��h���h���'�:�ZG>ґ���G��$�A���W�WI
-ɪ��Uc��X�N�U�>MG��hU���A����T�]3�R�g_u��S56�Lj|>��x����g0z�I^]3�%u����K:�J'Ry<�3�ֹV썱�������2�$���ȩ���+	\��c��Ӎ��3�������������_=:~b����Put��1�/�5o�6n��	u�	4eYv)[򌏎�e��@�X�'��r���h��˝�(�P��*b��C���y
-63�"#��u� XPW!Y���e�aR%@���=��P��)�jQ."��aC`�j84�y��dY�C�^�w8Sa`��t%�
-�l�S��a�z�GL�U�^J9������G6
-zQd�j�_L_�k��Ӹ���0ADg:�Z��;Y�& k��V�!��+�k�o�.L4\��7�s �_)�6
-���Lߴ�'������J
-�e���2	v�4���M��I�R�y���	=��'�T=d�8=�}<���a}Jͫ�C�����JQ���G��
-�bTz�4������%�E��c;�!������z(�x"��I�A�u���ՔG�,��P�Yqvid߉���
-���x�H~Ʌ�"�/��^�� 
-ԣ���A��|�x�[�ΠGt_쒓�:n.\�9>�/���������T\����k\0Y���^_���ώ��R�8Ʒ�e�+ޅ�7h����8��Q���{�|/������Ra <�|�5���L��a��h�\F��n(�����K܀��íŁ�0�M��Ļ�����{���Y�ߓ��Y=b黧(�#�LP��?�W 	"�+�
-����ڑf����6�g4s��J�]�֕+�'��������(NPc�,
-�
-+���M����M���0P� vU�,�������@�棾��¹��n���U�S��� �2N2��z��sX<��
-�����S �����.<�.6������eF�a���8��W�P����!Jou�\�tᅹ�oU�����h%v�S�ȝ�z�M�L���S�~6�_aM
-�;>��v|�#�'��6c�hwM�7::�*�"�E������6[�s�iձ�_�yh���iE�Ƣ�h���#{�����>�>?;r���w�$[�1va�[�ԃ��S@p�+��_gn!�?]����Ua����r!�x�	���]�
-��OW��g ��]�)JK�O�[Ȣ5%�#�����|��.!+\čt\)�4�t-��D�VxT��N}U�0�`c ����>а.�N��ԧgIǓZ��|��6�j�[�����<�Ҙt�
-W{f�J>��t��e�A.��>���8
-��L�==:j�?V\_ҦδM,Cc��������@�!�:�/C�&
-��e�H��ʌ�	���f�t^)�,m�y؞�߉I3(�L��FI����W�.�t~�-3�c�Ӽk�?d�hXL��1��[�����w@x^���7Z�9��u��pK��}H
-Ԗ�b;Va���|�~�����
-r=e���x+��i�g� ��(�w�)�l��|[3l�:���{��[�唌�Y��P�0�b����|/��9I������r�b?��
-|r��,
-��0ID<���{u1���R�W\�w�.�����E�lPD=��[�`�*3��'�lƞv83�2�o6q���A�%|+dG\�p�VX� �`Q�|ډD�3�_�;�l����Ͱ�i���M4�q���*iR�ї�	��]6P�3��R�� 8���M� //��W4�<MofG��w$����eZ�����M��[�5�hu)?u�lu���F[]5�p�����.ksyu��6�o���6��kN�+@��6W�㺇����Yލ��V𱳬��f܆�W��Y�u���~j�H�,v�#��z��Un���f�u~ҟf��>pi�J����� [����`l��h B��FK�O%���g�]Vaϙ���b���YY��iW"��d�¼���mn�pE��v&,c�U�����ixH|_犍g'{����NFډ�џ�"�+��b����7���*Td,2#�9$�U ���
-9�3v�t	ge{6d��Ǣ��c�+�ı��4WaA\�U���,��*t�,tQSq5
-=�g���{�����D��DjYcq_�{"ugcq��@"uwc�@��`"uoc�`���DjEc��|��{�6�C�kx��k¶k�=�k�8��`�8]�f�X�ISSq
-;Ý;�xճ0b�c7V'ӟ�<����E�	�D"��!w�.�X�D�	9!�`!��:!f	��@t����D�����@tS�����%�>Q_Q����#U'}�D�N��"���LӪ���%u]��(r�}[d"Wz:����Gƙ�� ���S� ��a"����!H���o��~�Y�[�����D�9|0bN��k[.�Yq?oF��o٫�(1�9��Q���D�ϊ'�?I����$�?M��\�4��Y����gl/�Iŝ�H*�}S� ��ˢ�^��ô�7����FWD�]\-�ѣ@�2b}=�"xY[�=��d;������e)����R�3
-�D<_�7�F�c��}�?F��B��� ���Q��(�B_8R�|�H�&"��pjaKᎶ��?5�C�����U�C��9���Є�Rv|X������j��'&���u��A�����;��=���G݇x���X��U�o���`?��S�N�'ׇ#|r=�[~r}$�o�
-����D�4 q�m�4�y��'#��%��?U�P�M�rȚ@�-���0&�5��l*4ٮ/Kv�N�����ݗ'3j��s:՚����9��d�\D��잗�.m˪�|ߕ���"i�GpE�{A�`qA���d��d�d��T�Su�Ov/��E�,a�<	��9Vh.�`�#�#%�����QqG��
-y��q����\�$��Jb�=�Ʌsъ��e�
-�AV�$��ZK^o���X�PM�$n���>n�� ����*�}����*��Yb�k~%�o�����WZ���Q0.�
-���˒7�S�U��"ſ6�xi\�/����n�ՙ�|�T*ܫ���W����Ra"q��$�E{CCFK=<Y��s��⍪)�/8u��撃�gX���)�=P�X{���ŝ�?9��'���| t�MO�� �RQ�X`��x�x�=,&Gݜ���1D���D�}�~�[9����H@��O�
-UY$sL�,�E��֫z�k|��V�yճ-�c�Nө
-!��6����<�m�m�94��s�M��18����:o5�-����Vs�q7¶���~�312����	�5�0�!Ì�V�_�G�@����R�a�%eX,����J�b���z@9��=�E9m�[.��|a�ԩB0�Nv�U�1s��tos�<��ES��8�5OV��5OV^T[.��� ��M��ėk�o�F���K�S��v�o�%�`ߐ}���qJ�
-����Э���]��oEG�u)}�S*�xJ��n� �B�z���T�wK�(@��{=��ޱd�>I�j*~�~����$S�5oKvߞL=�/�";[t�j�
-��?7�B��RN(쐹;������.a	��c�c��c�o��a�7���̓��'=�9�Ex�w۽�h?V��&������qIp�OQ:�M�'�4T$�ia���
-fL*ܞ\�4{�VX������\��4�U�e�a��c �#n�p|\��4�W�-el�T��l�VYS|O���� ��"]�H?�"� H��!�����i��SEz#=
-2(t� �BJn�x�<m��eʶKʶ��<�vgk�ywn�Ȑ�f�^X�V*\����v�w�H��PS�v
-
-�)�L�N��v
-���0i�aҾä}�������#�I�I���k�vYF}$
-���h]׋R���<�4�U��t�CC��GDq�Z"Q��-���w��ݍ���8A.��0�6�	����5�8҃<����wx�4��q�ƚE1�Ł�.b�F�jŢ��#�H��#HHڤF�qQ�rM ��;M`Vw�lkDW��V�Yl�YLZ2�Օ
-���"��Ԯ+4�œ��uQ/Ml�6D]2r��`6�Ӄ�IFM��3n��t���c;!� 5|��&FN:!�^I���Z#�dGݳ�(.1�L��v�73���QaIs�p=���S�:[|���`إ�~�������*�RE/m���6e��D����L�ǯt-�pA��QKfw��;�(��]b�P�n1J(tOKn����W�	9U'��=���_�AL�=8x��D=T�.��s���d}��d2���B����m52�M�1�W��.��v<U�������u�$OI-N��e.U$3����,3C�����0�FkH�~�΋Z��T�~������
-�����j��=UP�
-����'�:�eqR�JV!*0;�7/T~�[*���~�Px������+��?��N�)�#�}���N	��$��q-�����!�iٍZam�s���n�F*�ܓ#�m��@�	��
-��
-��Y�z�
-�:�6��`�� vK�C���V4�xP��^�^���m.��2H��
-׷�E�|�7��*��
-g��*�;5K8')����U<0���������:Y��`p
-��~��� t�v�s��.�S���o�uԀE� LZH���ַ!�]�ͮ����(�E��?@��UzLjK�wԈ�9���� �QUα�i�,ߧf�ᓋ���&;-.��h���?���F�۹�	�˧����^\����܋3Ћ�˒�
-`��`O�m����`o`��q��k��G'�<�a�ɴ������DOp]����̍�H�����8� �R�����r����mXn9*L?��[;��t�9'蠣c�Z�%������Y?��X"k�*��Y������ϣ#�HzI�I+!<�9;h%���#�������g�!(:�^�GN�� ��l=���	�t|ꜜ �٘�	`�;�6��/�`� v'`�6���ޘl�p�#�e$�v$����cd���s`%��u�� 6/f����K���O9�7W80�k/�bg<M��+M�;�r6���f��8�p�ZX`�9�� [� � �z'X`�`��'ث ��6���`C �s�
-=������0����|�R���x�Z��W��5�ԳpH�H�֓O��'��4�3��ԦOn�;�Q{�UW�Ƀ�?[�Su��o\�F!�I=QŲYby�MOH,����1X�H,,�SP�8���
-1\J��3�~�W��)ഁ�#5�I}
-bz-�FW�ɋ��5Zam�/�Qj�/��N�4���b=��V�����x?�Nj�������E�&EuL�#DQ���A<@|O-�*)
-3[1'n�3T��]~%}�������ؖ�A�4l��0�B��nУ�4	l�Rӓ�����I|��c��Jٹ2S�C�>� �dANr2`���%��Ͱܥ�Qp]����:ِ�FG��᳦�>�&���/ロO͇�ɇ8M*q���S�8>h�*[�)�s��U>���թZy��m�p[��,�M���=�ڬ
-KY��.O�6�#3I�w��s=�
-mXb� o�b�+Ja	�qez��UcG
-�w�fy4�I?9!��փ&� 0�i����uTs�Z�{�R����m�M���(+����M�V��Y�����COb=8�a΅�sa�9v������������5t?�m���u�L�=ߋ8�H[,����cux�`�/��r�����3وtyT�}�gH���a/X9��=�Z*�K�U22$����!�a�D8�
-��6q�Eg8p,5qpG Qb,�x���:���w��sc�C��<�\E3����{�G*1yiN���N�~�d���"N���*���=�4�����T�Cl�+}O�C
-�������l�?�E�úF�Jo��%U2�F�ќ�7GG�z�
-�_��u���;B�['Z�;h�.0�uA[�GD��
-��X�T[�uA{��'<�FD���#�dqG��G�MTmM<���7�=_���kY��;�
-��#"/&���u3��~N|*���:�8D��$�iԝ[�ic5��gt���]�mZj]Kj}��]��_�ZC��雤':�&)5T�&2�9N��	`��^:8�xe�
-�]��!�|�l�F,_Yrl�J����� ���(7xO����\7�k[���j�|~Jߑ�v؄���{�W�F�"����	Ǔ���Ym%������ ��w�_u��%��k�� �h�ÆK�
-)�)�ن+$p�6�Uduc�Qn�
-�4fV�H���ЌW� Y��U���O: [+��
-��Y�Q�j s�8��b���(ΛB܋���{qra^d���8�pu�9�z3R͘�U)&�WF��\�Zv��j�N֓zb\�N����?�C	v2:4��	-@�y���y����&}zS�@����=
-�k�5��*b����A�,7��saЂ���ۈQȎ����yWdֲEc���G��媘�n=}p�2���=�O�i�3Y؁�4�W�ȹ~�hW��]L�$�<�ODn�=,��D�<���a��B7�iVH�Ej���~:�_)E�$���? �����&����y�e��0��Y��p�_����l0�.ԃ�:5���p�gH?�Մ��
-�b
-���P��.~J��g�W+~N#�/Pנ��e�X�mYw:��e��̺�/��%q����ۭeޕw��*Mşg���<��"��O�K2�e�
-�]�ǌ|�o�y���*_��}���l��:"%���F����!(,in���l�ls��p#�v���'x򺵚;��>��G�2ټ����ͻ�-�x��#�>�
-i\���W@���u�*���p&�����"�u����KJ��~~�h��,����s�a��j�2a��b_���ߏO9�+��D�#K�=�
-wL������[�蛌(�!�m"��K83�FAJ�-������@�4�\�ToS��&%}]Da��^,����>�dVi����*MaC�|��%�.'P�ػ����7|*+�G��ݯ��5��^:�;Bs�cq8�;Wč}��ڻ#�⹠����뢏W��,y��5͘�{f.2�)�A'i齨�"x��/"�>������-�-��{E�\�/�H�p�tR�0
-� 1qo������T ���Ĭ 1O���|GyE�^�!
-l�X����Kͫ �[� ���� OU���6����tx��^q��C@����?㉍旡Ra ��^�v��
-ID�C|+a-����Y�`j۞���E�3�� dM���PS�2�º��Ӈ�8�w��ZL�q���e�H.v���;+5�TN?�����U��z<�L��u��ުL��Q�ֺ�p��w(D-��k�t�����o�h��	Q��2cz���4!�jFC[Ҥ��7E��Rh.�����IsO,�У��m�:>�0�*��WX�A)�2��D�F}�y�6h�hsv(�.>��
-!�
-)�h�8��+���m6�I�@�)���Z6e���$�ѳ��Yv��r�'M�! <8�^�����1<,����2S��y0�=����L�I[�׹P/EhI�4��`RZ��?�n,��l).F��{��cU쟚��|���
-L�����<5>���k��]�f%�s'��*�P�����:X{*�8c#
-�f	_?Fv�$��g�
-���;�֛�GGq�̚ǰT<�-3�w��rӍ
-{�<��^
-�k`堉����[�b��G�zP�55T����O�>ʹ:��)�͉L��3�e��=7z���T<C�%��J8�VR�����b����J%�@�U��P�`1ժ��Zvɫ���񭂛�����2-5f*
-2�X}�f�����#U[q�����HX_(ܧ�V���f
-��H��ȝ�QFE�Bwm����L�D�lGb�|�x!w�w<�l=`��Պ:���V/�A0fΜgq{+ލ�J�\���4�z�Q�vaשGr�yQ���۟�.��[�|���oIN�u8dϚvd����m�Ǒ=��%g���)N��2�p�(�����L�����0���u*������i�>��1���&��?��v��Ҹ�R~,9{P}��l����?�OY#�.E�J�M�Ƒ�5}ėk!�%�=\�۶G����T�)v���T\�[[W�jט$�G��Mˋn�r��P��>�ؗ�
-x��D���XvTʦq%1��Ѽ���j�l,�*��cq�-+Ƶ�_�)	�Y!�6Z�nok������@V���)T
-� �|6�s��\��[52���h\Ϙ�l�Oַ��֛:���m��q��:�Aץe����tKn���4��[� '�i��S�>��`�( ��k�����X��A��(v�K��J�Qoϯ�������TNT}�]�mT��Q�.W�*V��=�����
-���U,R�c���d���Ԅ62O�Z��`�ؚW!��Τ~K��8�`��:�� "6�"���ӇpK�7�3݆q@�0�0I�=̳#-fG؞0��*M$0�LT����<�u!�'��;����'	�E@����$p�W�1���j]>֋`�W3~%��
-�'-łs����L������/,%�W{��wr��G���Rcv2���7Wl�0�O׏�OӐci�Oͬ�>�k� �Ѕ6g��Թ##0S�:���h��e�+�/Ԥ��N�D>�
-��/J,�l�M�DP)QDKw��
-Ej�bxY���&�F�P_�Ï�&/
-�b�+�ɢ?'��,���nf��?��(xO3����D�#6�H��6{���uD�� vL��y}�ǒ�!D��I
-��F� ml�rU�S��J�/V�;�x>��w��
-,m��~]B$�"la��!�����I�3b>�%�Z��_q�����<N�U=;J4��h����$������Qã>�F}aԚţ�*���T�ֹ����?&�5���r�h�*w�bv��~*��I��̻���;8"ùl���C�;A��8�=놷~~O=�/N�O$Y�g�.T�]P��#��|Bnax�7[� N�0:��s�e�}�Nt���,t%�m�T����[BL�N׽�\+`0`���;{Aqt�EC�VO\05X{=�a�0O ��i��H�vN8��`��-[���(�bm�BV��	��K8�~A7��Ã�}ѧ��N2i��z�s=� �B	�D*m�<p`�O1=>d?����s���+-չ��G|�t��By���7E��\\��ަs��nq�o�7�V[��+����|����9B�X.��
-x@$�c^�qN��#W����WZX����.@�[HP}0d5�,��Y�R]l����Z�0(�3v�N��o�@{���؅Vm�j�XI2vV׷�������0�Dw�hnSK?�Wh��^-��;��80bn�qK�R��T�㥪��$�D ��_�v���������Y����1}6x�>��m,L��T�M�&�.�j]���cnW�H]ԁ���7n7[�7+������]�T��1B�0�2U�$��fU�cX���b��X�Q�U!��e �v!�φu�+�&N����cr��DeZ��Uڞ��FK�F� ����G8�w� V	M��6�l�ɤ�!&�c�)��k���c�j����5�[|�|#�h�Qv���7����O��ew-�Έ�+Q�;�
-��	���+-��##�[G�P�~�9�D`!f�.��)�*��%z���Okh�*�3�l��A�ޥkLZ]cR1��C	cqc
-ʍ�C��X�1Fϋ1�x\�h
-Eg|��?��gJݟ�����	棬y�9���Ŕ�dcٸ*f).NB�K�������1��=N�(?(�G�R�,�;r�,�]��+��X6>���_W���Z�o6�3~�)-Р�ġ�_`�=T�gȄc�;�c���ѿ�~�ĆN~���K����ǘcK����|8/&�[v*�X���ZT��P�d��U1J,�z ���vr�����@�&��I\�M�8֜'���ͽDM�D+�h�4T�5QM�`�j�	j���:�˹<&���
-]N�'�V�����ɧn�"�r9�~qߊ$��w��io�Y�j�ZiM*Zu��?LټAO��:m<�ع ��[�]q��)���+�>mî����+���7�V��eT���X�?�3�Hr�0F�?H�|���_��e��`V����dT|��8�A�J��_�J�G�)��q�6�)r�[S�*ū5c�V��S)\�͸��O�s����ͨ8^�l�fBF���ʉ�"���zI0,�������=������i]ͳ�Z�c\���EV(el��k��\�zJ��
-�Ƹ�B7X��K(�$&�"�B��eJ5;bZ��X�]����TC����Z���9��^������g�-=^\���LI�᛽�M>�A�*�f�t�x�˴�2�}O���gؾ�]>�4��d��J}� [�Q��F.�Jˏ��R+]yL�
-���ȕZi�1����*��0��h�5ϭI&�m���J�&i� ���l)���
-����������o�;���Od���ϖ��$�OZ�I�O"��)Һ$�C�u�#����WP���i���{��4�r���^�顩��>�X���O�'���z���~^Æv=`��B���2�Jq�DaV�$�K��f��4�˝��$wu������f/H��]ǭ��ܯW1Вѽqg�<}����
-sV���\�ir��F�ك���(���HEŹv��������Qٸ2&���c��EM�pjzW�|s�Lӟw��N�1�QuBD�C�Nv�f&_Q��"1�W8K� K�M������h=k�}�_�,aM�3Z���W��UZe�-�:�*��e�Cβ�!gY吳��b�.����_5.��M�>���^.���-��ƣ��,���>ls1q6`�S��I������B��?���>�Q��~�?����ra���R��X�X�v7�;��?0�E�����Ht����ɠ��(;ܼ���v�K	3�o#T���!�'�v3n�4���pWT0h���Tq�g����.�g/Ύ-@�.����Qĝ�vE�9ߣ��<��v���~���L�������XQ��0>
-�:c�A�κ�߳�%|'%��G�mMھ�n���u��}&<V%��.O9*+(�j����Nz�pdԓ�-��^��B�Ⱦ�l�!�H�F�W��{[����6j���@�G�}DX竬(���)<�����0��_�
-�H�^�"��I8H#�*<��P$
-+���Q6�ǌ{��O�x�#	���UF<�u���ۺ��R:R��&�Ԡ��� C�7_1y��ֽ#�����Q�It�>ubp�K��;A�ԉ���+�i�ur��1UߎN5ky��[!���C$�:o�u�0�(�����ȿ+��웞BQ���l�M�d
-&z96:�x@�7������T��w�(co���h\ H�H�G��P�ZǄ�]�Ŝ�R���~%F�qW�:
-b� p�\��4@�1[�v锚�|��r-�;<Žfƨ�+�.d`x��K�!���$�l��k���y���5�@�f�����P��7�V	Bx����5��@�"#d=���qs���R-�Ƚ�V��0�k /���u���r�K��Բ���{�f1n�]���ֹ���^Z$"u�I���ӹ�/�}Z6Ŝ�c�{����'ZͰ��A�6f�r5빬Wc�؀���� j��k4�s �98fz����a��,��/�ĸdbK*�?)w^2��
-%~�
-�Bͷ���Ĕ*����?��E�{{I��[r�&��c�_��ψ&��|�8Q8�i��N_~�Or����	_?,s�^��X����G��|�[_��a�G������,�m�G<�uħ�Ĝ���9Z� [@��h�a�c-/
-<	R�.kZ�4���bR��U>q�W����v(�D"u�)8'ӺB�3�U������4�'������澋[2}su����I��r������ga-�ym�Xq�8�Ҳ�|�xG����/N��g����<�7���sq���W�,�-Hf��������Q������w��O� ��ނd*"n��v��+�V�W���O8IO:IԜ[]���X�zf�a;�CX����]��流����ӄ\sZ�iи�⭻�W��W�T�އ���S��"�����?�j��A��[@�N�^�O�н!�ʇ{:6и>�xs!q�7���ѳ�������Ӻ���7wS�3�!��SD>�z����;� �4���
-m�*1q��I�\!2^�]�7�_�A�YO|}�Ϭ�h����;���2+ecw��.m��;?��xg�\?-���Qd��1�^
-������9r�
-��%A�D�E32`+�*�K<|��}OLdו�4����Bq�SEE^�1K+���eڳ��B�pk���j?������p�ؒ�,�P�)��"���ʱ�}����Q�X�(K�r)�SN)���2Q7B)�R�TƝ�h�+�!3"wV#����,�֘x,yk����X��5�>v�ЉǢ�Et��Y�%�R���]n�)AT����p��ᢋF��5�D���FQ�����N�Z1���t_���b���8�i����C�I�?4��ِ[���zʆ|���y�k;|὘�k?�.���1<B{��U'�lv�s���^_��v�d	�w)c&�P%�O��y�6yH��h͙Gy��kϙ��i*�W��J��	�1&�V-�1���L��jKjm�Z�7�F��P�y0���ߔ��7��m�jx;�UJ�u^�jR-V�Iub27#U��)�y���Pu�:��D��*-�UZ�1o��m����5���x�/��ڽ&�>�����E�k��%2ݯq���ݻ���a(�}�W��1'w�4�ᕎ��_��j��-���7�6G����(��ze���ie�œ ���˴�|w
-�D�އ��1�T��FÃ�Kᡯ�"K5�F��P�c9	��XE�
-������Ia���
-m�p��e��XG���^�ـ�����g(���ި�����>�����-�6`�?�I��Ϭ���y����W�Q3��3�·q;/��0���O@D�_���Xz��:w�Xәϭ~Y�^\�ͯ;A���/R�:W�v���
-k"BT `��M���K��b5�� p�	S6v��EjEPƤ�����"��+嵘8E]�Q�\�D)#|�xz�c���4�}�x�$6�ڶ��Ԋ�:W�������q�x�GP���Wb�;��d~^
-�+O/�	8OF�d����0;�\H�t��e|�T����/��"2��1�����I���I�\��(�bSY�L���܁M�^l�^��^�2�x�gz�d���E����B�槼2+q�z4S���Jݏff=f}>���5�[:�{kf��Ж|<3�	hK>���$�%����m�m�⣙܅�����f��X&wQkn�l}Ϸ��6�[�Q�~7�wR����q��q��q�����X�B���z�rI���Fq.MA�u+�oP˝72�e)��6����YkϠ(��JB0�����<���)\3��OҜ�ɿ��)�hv-��z�\Ѥu|∄ެ�t�L|�o���W�`	o�������}�.n-w��[4B�R��	]F��N�r
-�wBWPh�Z@�;��&Z��BJ��	ͧ=�b't1�����r�^eq���%j�X��$�9��]���Z[�Ԗ?�\��L�g����)�Ϟ
-��ն����j�p�.�M�AOρ�AӚ7�0-�*�U�_�%�$t�$�\��T5�շ$ϔ�Y�jm�G��%g��7��m׭7��\S�[|T�+��cYܪaVR��p��y3�Nn���>�x\�<�I�JO�J��)(���ܺ�U;j�şu�F��`�Q�=���FW�v�^��o�yܻ����/��i��KS��J	��(\ih5�����Q�o������	�0�/̩�^���&)꤭��k�����k�qqcٸ����Y������|�5�H��m�V�A?׶"�L9���ĵ*_v��9��5S��&��#��1��y�=M�����������Ia$�<7�?W���qr�۠�L�ѝ�=S*=��3����R	
-�#+�-S=%�T6�-��V�|FkxrdD�[q� Vf�)>�)m��1���m�b���{��%S�N�%S䜂�M�͆g�T��B	��W.���@e��͚�s�-��ad����|�.EO�����גV�gc��	PJ�N�ܗ?���h!���8��p���G�=h��=�B���v��Oiۆ�Ν��>v�ќB��;_�d��@.PH���<a���vB���-_�$j|a��*w�S���廅���"��0Ջ���T�`j
-*BRnϯV=s,R/쇙�,e�J�X� m�
-�g3��i�|��k�k4�p���!DHx+�2-h���Y��3����_}@�
-�"TCWG��(D�Cl6��~]cc��P���N��6"d��j�We��T�č�j��e��L��֚[��3[ƶ`�j�C,� �9��X�e�'rHZ�R��Ȑl/z'bi8���?�(�`��wy�C3�T�L�
-A]z���9�*VA�F�G`�@?��>�ˇ�p:��<�՗�,3���CN<��)�ԇ2�d4S=nO(����"��Y�8L��Jo��q��HHz��HHz�؈$��b:L��ۄ{S���c9>l��W`���� š����)/��6k�2gX����G���(G�<�=]ڛ53��D2A���Ej)a����47Cѻxh�<"�M��f]k�m
-�˻<��tX�����z �q}-��p֖� �b&bCğM�?c�y,S�m(�v؉���x*O�v^W���O�B��-�f�����
-M�P0�`3mn���`Ë����o�R�����p<k�ĄX�}t�M�St�ʖ��ycѢ����t�)ܘ��N�!h<����8��Ɵy�~Q��k���1��Q�i�0o�>b�Z�,�2n`�b�Pq�����4Ж�����4O�z�t]q=��:U��Ln��t��c�� O���Vk�G~c��QU��Y��,�N��KV�%t�Nk8�����U�?u���[R>��ʣ7�����E�o�R�5�~�G�b�kχ���c�'��������ݟ�M?���>�}ʻ}!F=� �N�<~�I��xX+~���}j�S9�_h��?��3R~��~�g,��E� >6pT�kO٦���3W�`��
-�{��`(-��l��v?��ߝ���}#�S0��� ��>jP0$�#T����kP��Cԃ����<4*�p
-e>�<��t�%E��YOg
-����{}J��)`���iR�*0 .e{�lGqe�%�n"4�K�}�ưMWM�?��`�L��[�C$�CS�Ч2쑺�N���yE�ny�Y鼹�G	0��
-��P�~j�[z�(���X����{]u՚��%\#���I�J=8Ã�P]�]�������!���f���<��	F��{�6��gzz��>��a/G��#2�hi���	垯G�b��f��@�[��Fv�7+�>O�
-
-�	 �^��<��U�|ŵ�v�ϸ0K?���?�w6���5�8���1`>�1�\�	��,�\����sy�)��VA��Pn��Pn�.�:��u�w5���C�l�Y׵�z�>��Z,�{�7bҾ��>��ڋD�����%�)�f܀!߅2�ߤ2�W�F�w�uֽr�6����c
-z�0�#NA�p�
-���As��w�Q�<\|L�v>^'B��F�v$�q��.�b��^!Qf��f������sK[��qrO<�T5i�Y��G�w�G�1��U����X�ܒ{̣ɹ��9�hj��7+��;Q�f�:�T#�#OC4�J���(�J"�淪
-�ګ���t��<^n�g]o��w?�N�ǝ�r/Q�dfJ�g�>�O���-x����D����$��xe���{&�������߂ƛ�j�`�L�����:�A���a�ы�C���p�:0�!��~��I�?iװ��;o��-�{,o���Ch�����~�?�߶�Y���F��,l��A��3�L�����g����GU{�1�+b	jE(��UW|�S<s ��p&}�ϔ��bs)^����"�ZA�3G�,�SW(R�&3x��#g%��D1���ʘ+l�q� �|�[
-��1��D������Q���2.����=L�y4ύ���g������� 2�1�
->h0' M!-�W'4�jd$X�t��?峑�����������b#ӯ;��?�|��,��`�<��M<I�&v�-g-��w ���d��R�'�-�ՎA��;����∧�9�dXG��2��=ښ��,'�$�� ��#��FiG��-�:��ۑ6���c3>6�~�rH:d�xx�j���Sw��+�9�`���G�^��W�#9@�b�wp�M�+q?i�f��H��yV�zwԇ\��`���P�!�/�z�������=���B����h��
-&�~KDY5�T����T�I�YT07i�U�H�:X��F�V��00}�^�+8�7!\Ŵ�-�t1��euܱ���+����v̕u��!�u$��Hܸ6{<���=g-uĕgQ�"&Sq�xM�eH�į���7c�=���Y7ִ�_ ��
-o���B�_�>���wD��Iݟ9_=q�r��Mu��M���7ͺHk�H�� �h*�0�Y7fۺo�˙8�f���Rs�M��4%���S*g]�?�l,�[4�{��l\/��V�Uq��3,P�2
-g�������u;qY|eU�~��X��
-$S��D[�FBv^G�n�b����4B���I��~d��aئ�;��(qw�@1�e;r��;� q����X����3�a}��]�7��/#|g-<��]
-�[\ȏ�� cb���E��X���r~���s�(���H̪�5�������Q���� x���[���f��wy���bi>�W0*����`����π�W9����5�����9 ���
-�B,���k����f�}�t�1�W�E���d�)DH�_ž��Bۿ�*+�-����L_������ �ܽqӨN]a�SWb�� ������]5�2�Jy�k��� ��o�Ũ
-Pܘ�p�/�*��Q��j�%:vw�����ǥ�k��e�:���&����G�M-�c�:���R�|i�����l���8��\�؃���&�W]=�ot�~W�k5������`�� �Jd̋���L"d��B��&"�D5< �:�&�f�ڿ])��ic��f�a� �f߾Ceᣝ���줗h��%/6���*���j�.������s2.�-n2�3(X�ف��1��������&GUxS$�(�7�5��aU��j���·!��'�p/���)���r��|{"�Ľ��"ﺪ��j��/B�Р(��Њi�`����^�
-?�Z��6�|��d������ �����e���x�.���N�~3Sh!�
-�s��}7�`��Fʹ���^�.��Y/���B�vSh���z�B���+�Y{(�/B{B��l����Lrs��f1{��go���N�[i��g���i��C,�C���g�5��Ru��� �{_ip*��fim瀬 G�*H��J��< *��7��1�
-;�o�W��Z֜�ʹؒH�pV�Z�qc�ҏ���;ᱎeөw�n*0�4����@��2iQ��3��Z�Cf��B�I�s=r�&�KR���*-[ƚ�x)hB�d
-�=�~"��ۨ<"��͜4(���~�����Msm��zv����M�Է��潝RM])��e������HEfM���Y��z����\! _r�
-vyQ��)�*���-��O{��Ǳ0�06�tm�4��·[.��^���ML;�
-�2V,�D7���A�s�nd����%�UO��O�!�`��jE��*���S���M�^�9.��u���y���M��'[e���~x0�:���X9�&)��c0�w*|J�t�Z u�T���_�X�e��X�|�!\�z����뾆-���;��Y�����ei[�nF+8"e��I���i��nZ�ēh5ΙB�x�:J���|&��Q�q����´�Ͼ:.��Wǭ}�a���L���!�\�Ϗ_�|�-d��㐙���r�d�i��g2\�1����
-Z�k9���3!~/v�]�v�Yק�b�
-��q	�m�l�����f��	�\K:�1^3��"����ٍ�]
-|��Zz6�e��lW��a�h/�W�r�1�&��ecq<9E&)�sU\.W�ǫsm���Ο��3O��b?ϛK���z���cRH�ϖ0��RP�yE�T\��v���C��	�1�G�p��g�
-|k1�C.]ݠ�oY��4=�yS�-�߆��-���TϔiBy��
-�'� ?"Ǡ	��f���E�u��EZIkc8�+9v/��Ņ
-W;o�"W���S��]J%��s_��)����8LL��p�ʀ0D|bW�Į��P�^W�(�eų��?�̟-��=�aP|�ӋC �}b��?�]��oD��%��h6��B;�{����Q*Drc������㒰�����[Tb�� ~�*�?yҊ9]Q=�++��u�0|�}�� �7Pz�۪KoC���|�]G	+�����9]!�C>=�D��
-~}kw�N;4�qM-t��n�ؐ�\�W�;xV��l�J��������8}��/����XCٹ���Ak�,�kҶ�ҝ@�Ϲ{�oOǉ�����>'� 7Ԫɹ�͚'7�J?Ϸj���z	/���`i� �i����]M��?ݤyKweqL��+��;=8i饹�Np-�ہ�y���+Be��TR¹1��v��]��Z��4y�4
-��.�v"��r���=U!�tf�j0b��@��в�>7yLe�OԉW����ެ���D��t\ͳ]����3�j���?����pr�ť/9�Vj����.4�� mR�N�x�r� ]���)c���9�E���(�%uR�2/>���CTM��j�!ͳ�����މz�L�ղ���F��@뻞»��[hq'����AK`�a���z�<��;�)xl$�8�pdqim|l�1Ѣ�A8��o����*(E��Ƭ �e�!�ߔqo���w�Ȗ�;�e}<�%��p-��A��!���8�>��.G:���*����H-���d�X$ck���H�}��A��2�k�w�=�x[���Te��NK
-��
-�8�#�قF,
-Il��!d�>0D+Q!ぬ[�@���=�3�"�R�ՙ�D�L
-z�U��v�˯b�n��
-��y�NecW����~~��+�W1��Ԑ�*&̯b�����l$|�O?��ё��O��\�����F̏F��d� �9
-G8'�G#At[�/(kd$dn�
-9��p's[�$���lOrD9eqM3W��@��1s�e���q1�#$���7.�ѿ8i�Z۸`
-4�tf�����_%>�U<X�:�O�'�7ƀ�?��%�U�8��9�H+ׇ��ܝ&��y�BDV�Է�NT&з��ꊽV�����,q|Mk�E�=��U��<��j�2�r�X^�v.�A"~�D�J��#u8����M�������\��^i����, n[�Kb�XC����y��q�a�tuz^����=�z8w�C�����cD�%j��4
-�g�T:��x#u?/O����$I�
-�b-c���i�o��~h&�X.|*\)ձ�5q�;kyM����lL�cX��(�
-�;wMA�~z0]�d���'�C>�z���y�ͣ��;�u%>C4�%�������P[bU@�8��k���=�'�8�1�r�G�T_'2��$����\��
-+���谇�^٫Lsfer[s�Z����2�� ���Ff�X88���G�ū4P1{2�M�����{20`�)��T(�~�丹�U�Χ�2��6�W�Og%\YA�3��z�s��3�|$Sx!C�/d<0]�%�
-�-�R�dBs��Kx�+�k�䶨UK���
-.��J;��72��x#����$o���@a9�����0n�bG��lFO=Q� ^A�����+�b������`���U����%���I�9�G���@&qDi0�ܶ��́�u(z�HwqW4�8�*��!�Sk�$��+,�����f{(d{(,T��z6�\�/t�qhB�S_�؝��;��U�sL�L=A{��!� ��,v���B;(�~n���~n�j������
-*��1���GF|}>B�?�����P�g�g����������Wt0{�CYɣz��Y�����糒"�ս��|��Ŭ�W���R@�ve��Wڝ�B��r�M�g��Oړ��{�R�*����omc.�%&�[��&�	��!��-h��{�J�;##X5�J�S^e�JWc?\�{�v����]1ī��}KW����-	f�[f���\�����c����+�2&qȼ��_��.a�X�n�H��0�R�2�^�B���2��]Au�H2����gG�ѻ(Z�he~~������X�ue�ll�te�l��c���x��8���#)�V�s�%,�ڈ�&����c@��B��e�W����� �>Hu��n�|�J�?���4 ��L�>�w�����HS��w����	��	��-�����{���!�=�~~��@�	>W�AU�[���m��ZE�3g�O���mt�z4q�Wj���4hTq`50���`HH�	D�:=�
-3���Ԋ�'�PW�xU��Ӟ��M�	���ΑU��O0��cٕ�tOZ��{b�'��>ML��5��tOG�J6�A�_�����=_�l�b����b�;t��O�a%�.�XNp�J;/�~��
-�e�Xf`�4��2�c�?�TdmZg�
-�,L���{���+n3�a�W1�ƴ�ݬ�堄�>���Y?q�O���<|++���<�p�{&{�7Xᷭ��QUK������w������~�&���܂����\�3pBK�n��G�y �I��R?̒�8�����XL���$�Vj� #�1���	vpnF������s2�U4�n
-I}���4�8��zs�z c5��©�y"+���]����&D�sE�x�9�
-\t�}����GC�őmW!�4&B�)��݊IM�\���73���?�"j碆���J�u<hͅ~>B<��x'؜��:�D��T"����m��V��%�w��[���{,��O;	���;��+��pD���^�c��e�,\i}J�"}F������J�s�}�,���b^�*�q���d%b�=m���mR�"�k��!�6i�,]�&MT��6iR��
-�)�x��>�|�@u
-)m����5��Ô-���u5��yHo�S�-�Grw�ֲ���l̟�7k�0s\�G��SR�Gh}h� 2�����Z�߅�`����|�
-�ug��8����cz3Z�!+Y=�H�);�H&�'P�`┸�ˑ`<��t�Uk�����Wz��r�δ�Ϋ��mKϐ�B�U�(O><���0 �C�Ó%{�&?f�q��;���c��!ڞ�$�+w�
-	'Y.���D�*wM/�;[�|$�������a�������?�U������T7�/�~�ŷu��W�ɢ_���4�3�ǖϜf`����N���e8�&Jؑ���u�N����S�w�bSw:�; � �D7bS �����
-pfZ����q�+�WIѤ�v8�ɸ����a�+V�+܈��Ͳ�p�����*�5 ���RpP�φ�8+����^��K����t��������� ���D?��N��uc:+ ���
-�>���p۫ĭ�J�x��Sb��5*U�=n{�ѿ8���
-�.�>�ݰ%�ه����՜�R�I�ך�2J���+*�@�r
-��w-�����_���B�EzЊ+�������C��
-�C�"6)H��-�i���#�ƃ���^En�iU
-9be��r����!��XI�-���W9,CQ|%���sq�օ.�����}�B%�������u��,ǿ!�W�C�_���P��t4�˓C�F
-�۩͌V���RS[<m�����ˆ�`��R �+�lz&��9��% ��H:�k;�=�s&�u�MS���EC�xj��Jŋt��ͨ�R��ǐ�}��e����:ҷ�!@���N��ǆ�mڠ�7����,���eQC?)�}:Lw����l����oĕa�a�e�x�H�B;�����U$t�3>Ԉ�����5t�
-��_i��]�j�b�k19���B��GYjZ9[���+#�~�/��w27z�o薪��gDo}�Ɋ[����@��ΐ� ~�/��"H�v��a���������9�?S���.񼂜����r2lI��A�ao�����������?���Y��+�W��"����k��v-Oi�,n�ʸ�>��n�
-�;��B�0��Qxנ��"̩F>��\���!����=�%�����6�~_����sZ�0�]j�UJmW2��3�z��v��c\f�9�߆R̰���(���|���rCӻ�l���ɪ�������':��C��f1,O<1רeޥP&�K2�VI�ͮ�m�����p/���z������ү�qmUV�T��=h��������@�@�5}��UE��Y."��@�%d�h��,����8�Ü�KY>A�O͟"˧ W�H����7sڟ������;,���WM����| ���[����������p~�=�D�;�U�ݱ�U.�z5;��f6�Y�%��!5'�ޓ��� j��Ȟ:)��4�9��CB@���x6�d;�I{��J(:P�q��t�JP2�*�3|�#}�U������$v~��ϣ^z>���+[.z���>V娵;8��ZG̮{ K ��X����j�®���59�� /�o]S	ͥﷸ�RK��Y;��{��%|9���9���x����_�G��*4�G�'�ҝIaz_�����<�sߟ�ѳy�}-H"�bߧi�$�n��
-n��dY�GB��<I�
-sIMF��V�|��K���F��� �/|B�H(BU�
-�Ѕ>@\�1�E��h���HV��(�J��'2��}M�:Y�ju[�tN�#����`pE\�&:7(}S	�P�HVi���8�(�F~��0S0���Ҧs.���?r-`m�J(�J����=6&=�0��Q/n�@-ο�*���N�c%����8}�Wat�Ş8Q�����������#i΀9�]v��cr�`�ٞ�v��$r��'�wC[��5Zޑ��j�7��h�OT�;z]p���Sm�?xn�X�?Ĕ�������:�<�#�%m�(R�  }�1Aݡ%Q��WM��������i�^o����J0<�ޟ��.
-"�.I��Ʉ��mÃ�.z�Գ��L�(n=7��iz�@���7�����[L�S��<�r^Bυ��A5t�s��4�;�}N�O��0��,�ϡ�U
-ϣ�>zv��9��M�Nʳ�~���0շ��+跒~�跓�t�o>��Fʳ�~;������ �Vl���:�܋�����w����5�~�ޯ�����oů���w�IwS/=k����l�M���ͤ�3V�cϗB�ċ
-�����}w��k���
-�f2�0�?
-���ͤ�h'�G<T���V;��o�*�*z�b>��'��'����@)Ms9�h��p@�T�L�Na4F2��L�OlY��Ȳ
-IXk~Xf_��l����ofc��{�iqS���E�
-�'
-�'<��	��gT��J�/����S�_Wjź֭��jF��Ris[�ǐif����0/S�I�X���)�����c��Q��,{J�t�-Zw�+��ș��l�Y<��!e�Gfm.�-J���-L
-������Q�l��G�Q�S�R�W�d˅U�g��n�s����ob>��of�!,�����ˁȾF��?�Le�ԑ]7H�� /��\�-S.q�!F��'�?9x��l"�c����x��q��m�E-b5J#��`��lb�߰FB-z��{��<3:������uXe�-�����m���Vkj[O�Z��Y�ap4 &�h�v��L�������ó7��>ɍ�G���~X6'��k�j�~1�o�P��a8����*{m l<,]n�f!J����DB�ь쨖��i�f0����i���U�� 6��Gg=�N|��Vg�ϳ��]�Ă�?���<���M|��`|_E���50b}rBG��QB�t�}�
-mi���Ƙ�]bd~>'�5� 
-�6?6������ �b=�$���aw:�K}��z�=�\C��5udX|y�+;'鉯BH�C�,���a�a���#��E�ĊF����	*eE0��.��ޒ��ᄪ][�:�7�W��=�52�*���>��W�]���`}�O�A��2�P�t:]mV6}�����Va�h�G�2:^.l�q�}@�E�q~�0�/�22��ۻ�(�_�շ>?�b�qg�Ѵ��\Tv�dp�v �[ϐI�����"�i��F���卖���`	�o_[%p��R��k�� si���W]c,e˃�nY�Xee]A�mLy�����g�嫃�X:��bY���-+��v�兠����ZJ��[V-e~ˋL�I�����A����[�O��^�D���^ ��h��V+�7��nO���*�;(��������� a���6m[
-�s�p��n��M�����SCt�����̕�x`Q<>MJ��N�<.&6M��i�$Qt��'�5��0|�� e�.}s�+N���z�l�j�	Ѿk��=R�謧-�d�!��qư�u�2��.��{����=����^�Ku�]��:-����<��Z���oxb��R
-f�_����>*{�W�����=���ކLbc0�U#�Rz��I��i�g� ��U�h"���a+z%��L�����	K�|���ιz�fe.��.>U�e.�K)��Dl�}=8*�	��g>�ɦ����m|�4v��MBi�u���qt�P�TXy* ��%�{u]j�թ����Ѻ�N6x�Ep�G	�xY�f�qj�=��25r��P,�ri��2
-4�w�j�������w�i������]�_��VgR�e4>�4�aj�8�(�����"2�d�
-�l�'�*աb*j�AE��I@a�ݩ�NP$c�M�<�r�ۄlJ��L�6�}Ê#5��� 왂��:�̈́G;���a�,�霊��l|Wia�匃�:��:�����b�(O�Ҋ6
-�U
-��H��;����{�ף
-ZR�Gaz��֓��<�Z*������'9Э�g�ld�lm�C�S\�O4�����;�����c|��[ ��EK�@��h��ƿ���:��(y�������z��� �X,34o[n�i��l�����x����$&���"1���O��LbZ)�&�ܰ������Xm��5��R�v��dt���1�5X����Wdxq�ćP�T����I�W�Q�(��fsW,������5��^�p6�Z�O�9T����,s�|X۵-g;m9�%)�z��;��.�Zm8轂�4U�Ό��P������`k����$,�R/(g�c.�'�U:�[[��FDs�AMX>��A��A�ʢ/eh�"�B�6X�}A`{��I}*���|�2�J	�YZ=�H�.(����������H�?\�)�\ΑW�"�>���EU�G���)�O�oP�ﱤ;�?z���ȝ�Ǳ+��۬��Ģ�\���=��l�f5|��IX-O�������d��\$�w�j�Tp�j�TkV�lW����!|�!|�!���{���
-G��
-���c̹��VK�肘2oE�C�
-�#�J�v�e�v�LM(�8`�q��C*��v!�ۦo�sX�r,�8h�qМ�V��P!�!S�C�vS���|�V��.t[/Z?�q�E�%l_�e�[���v����	;o+��	��Ɔ'~8���m|5��%�%�n%le[�c$���B���U�*�T�V�ɦ�4�ƶ\&L���.�d*d���/���o��Տ#*"e�<�FK�g'�0��a��5��<�H�X-V�坠�v��ݠ�~�彠��
-Ϥ���M�p?`��j;1���h�҉5�»�{��=As���n�d5nS�`��U��q.26���m|��h�K{������ĞP2�-�no�j��-�N���D�)�EY���$���HS�j}SH�m�
-~��&�4�69|Y
-��F�� ���j��Y"�^#F�5Y"R��8
-9ͅ�����8�"V3��n��)X�\��SK9?�s���e�Cȿ֔����/���ɿ��F�����u �V����{�K�#H_?P7T��'�f��	gV��A��L�A��_��,���
-�Z<j���s�'�EƔ�t����U�R��k�W����������??,�� 6+6[�Y�կ�Lʂ>�z2���J�b	��� ���L|t�
-��z��a��V�q\_ ��@���2��0�[�I�T]&r����B�3ȴ�3Up�32����UΉ��s�T]���<Vܮ�HN���dRgQ�v��`�J8�v� ��&�. `W�2 ^c�ܙ�ǲg��v^�+��ɷG����r��I��#�TIj8��L<ZU9CH{US� i � �)u&��� ?i�	 ��f
-R���V�ڿ�q�������co��/P�>S	_��7�������5"��x/�ތ	���By�^�7�z	 Wm���2CX�����B_8���䏸V�4Z�ӇK�l@������5=��z�!���0P �N����n��S�q�S�	-���9V��	���To��GP�[&��~��1swc#�F'�T06%��z(2ZJ�)�UR�N��	������ߏ2��y�� �L�N�Z��M�����"?���c^��Mk
-z�����omIV�Jĥ���-N2�q�V�һU�ޯ�:���Ųy�+!O�	�$=S�K����gRW�ʔM:y١%)��F��Oo� Gy���r8ϋ�<,���^�n�u2=��?��.q�I��AzŻ�굎ea�r�Y��,Q�R�L6��WJ:`m�|�ˇ$֍�d	V��A�G�����(�����ߛ�������.)>*u�&���Ŧ�y�";�F~A�s���}��edR* ���%�\���f��K|���Jc65b�0�'.�Lbv)�\������x�6ob.�z��|�K=M�vobA)�2��>إ㾀�T�q/��p_ p7ԣ��|6���DX���1�T�vV�U�?�'W&�>-ӿ�L6}J��JU'e\�Z��ˬ>S�t/��NQ�d�y�C��^k����MW�LW$�R���Z���Kq�mjR����.$\&��ɒą�V�`�b���y3>�����F&�K�9�߀?��"�Ή����ْ.�l�r0�..�h*e��
- ���@����*���qq�Y��\R��j9'�׭��ߘ�Y	���䢝��얞,�ros)GEm,��rԖ�v��#s�����2���>����S{"JP�]�W�F���5N�fyF��(/g�&x1�#�6��ťg�/6'dH����/�䷍aØ,�0�	��2�A�8��� �K|��m�C�e�J�_�
-2CS�n�w����ؔ�J�(�miSr��0Z�
-����nl�h�\)Y
-��|�7 cZT����-2�k%�`ki�4��(��gn�^S��r�7]�,�]�5zgq�W�ƍ�5N
-J�D�eg�پ?��b����*�ͧ���؛<*��ˤ�-#�m��V#*C\w� ~¢[��b׌F�%�ݻ�%��G���Dr��r�Jx�-��&$W��ʙ�q�g�Nk���&NA�?�C��漬��<�M�{�<:�
-��K\����h�Nkn���6N��NY@�2�:eJ���C.�&�z�̛X��ob	���D'�����x>�M<��s��sh�h��js���y^��}�����@2�k�w`���"s������=%.W�'x^Fhv�x�<��Վ�������P􁚁ĝk���s�W�;_��������%`�`�!�yP�d3/�� � � �`\`= 1���56M��%
-[��|���>�혇�Kp�ES�{���A%=V���%J^�ոF��ZCc��Jot�Ho��!��/ǻ:�Qj:^nM��fb�"�,�U^����L�uM�@��,�3���Z/K�`��Ц
-�Y5؏�Z^4n��n�"��˕���V���h[�J���E0���4ܻ��C�ʻq8�W����#u�0{����i�l���;<ِ�����oZ>��w��k���"��;=\-q��t���ܑ[�L�yZo�4há&����U �ߌd�h��5о���hT7���5�X�uY]Xb�X�
-e�F�y�#�������x�����g�ۉ�O ���o�P�8F����~����8>���@���j��'���81G�O������կ��U���N���?p.+�<������`H<�Z3�s�3�j��	�)ξ��:��S)��s
-�m@��ژ���l��!۴	l�p�^S����� ���Y#���?C=����3���G���82<i�ݬ�J��R�xq�a��߽�Q��̲�n.��:�C��-�}^���83^q½���Y5�Yue�q73��d���Y51.���R�0RW�@���H�G9.�kz��C���{����E(�=����<]�5,
-6��2��o�`Ua@���'�yX�X��y���[��tG�5���#���墪�{�J�p"_c��4�?��߻MJ�5��j`�z8w2g�;�3�N�L�¸�ɋ�?��ª�5�1%����S#�bF|m ���a�Fa{���ԣ����X(z:��-���k���}n��׼�*,�c����ďA��(e���k��p`�
-� �
- W �	�
- � � �ŵ|��k���T�5 ��	� ��S/��F�6Q}�E�6;����d��^Dkp�5�S^��>p��4��@��j ��nX����ʣq�{����4.���.JT#m>��z��v�T	Gښv�o��r/(ʽ�O�}�Ӄ�0����!3�p�y=>�)p-0�T�	\��BS��k�RU�r#�� ����ۦ`��㒞3�=�;j�;R�P!�DO)Q#%Rj�H-��{�'i7h������
-n�hJ�j�O��o���Kֱ�\�/[E{:��j�͖_^�:ZӉ[H5��C=ԝ��{=-�Ͻ�?�|����FW��G��/z��U3-}�G��Y"�3^/�G}�6�z�gP���� ꩜Iv|��%�@��$5�J�R���i/[���eң����� F���$Ic!�8�eE>���B�ϐJ`ς�?�ީ��r��؃V�m��j�Ru\�׀
-�{ԕ򏬢%��8�=Y����P�j�T�R�DM�Hɒh�$�.絑��T�
-
-������/�L4�^���8�GL��1��9bz"P��=pjV-5/S;�Lj����O-��s<����ab ��z�B�I!��I![�P?RY�sMf�%5)�{��l��BL��
-`�YkdޥP&	�L@�HĦt��,!���Y
-�qK�ig�$d��|����۵N����Y���S���P��k`��N�[�3��"t�6_tJȊ��C�b�σ�TՎ�𴑑�7Hc�Ufߵ��Z�u@�&�E�Ŀ��J����Z:5`��V��i��T�s��Jt���h�Uۈ���
-��+��qLyFM�&�i���ٹ�d�2����Q��*8[MV$�
-��l�?(�s>���K�����zbF�^�p��2֎�i�_�gKD�;4�a�>�Hk��"%6BD��»��T?-R$]c���7�����N��F���H�;�5Sj���)�)����%a^��h$l܃a� *�=R�>�mQ`0g��u�g��0
-8J�_�Ró#��V�7>^ʱP������m�v�`ֈĆjv@(�Zm�sDn�%I�~�j"	��U>�헋���>?x:�W���Ld��R�<XgO���Б���f��붞�r�n���P61-�b3�|��l�nw:\OsQox����PG{O|�6O櫯3q`�zfh@��sh�r:�B�|�����b��τ�φ�sB���
-:0]}Q�o�z�Oخ>^+ҰY]�UmV�����E1�?�|���"�Ud��U0V���ƪ;|&cծ���(���jB��9��?�ucե&c�n�X5�s��UO���gCl�zN��U?���!�s������!��o�����[f�,��?�P2��0{�*���כcAQ.5�'G1���6Wi^��ym�Od�
-�
-�g1����MA��v�ꨩ��^5��ʳcn�Q�B����PIY�[l-��њ�ɥ>���|W&2B�k��"�&���x>/�|p�
-w6��fi���w���R
-)nh��&�]���7�u�'H]��34��.a�$E6}���c�8���R�g5�h�.we������ٝFv^H�+[���֞�x){�%2^�Z�K�95�ǝx�M�]��Nw�^�>L��l��Y���xwI�Q#[}��[����]�y5E.@��c%������C��V"�o�9\�i3�
-���&��~Z,�8�]p�3����G�����w������DC��2�fs}�2��Ҁ���|Y[����vK +M=/���R�.�H�V��qYh���{[ �f>ړ���j���,�hU�
-�"��{	ۡg�:0�������<NB�����39Sc��(��+�����R�
-� P"~�6rb�v��>6�TY-�纸
-��#�j$�I����qj�pe ��n����WIqCgo�
-��׋��L����V�����;�8ӷ��@'(����pޯ}��L:�B@���� ��{}�\�qN��#��1	��0���C�H��;�d>��W��s��M�V�F�����Iu~�'�z,Y6���=��!��g�]&�J/��4�������B�a`L� %��)�z>t�A��K\��#�x��f�ΟZ�v�(-�ِ��4Ksi����4����6�v��&�e;'̲a�yE�8���}��	��>�q�����Fͨ^���\��
-{ZՓ���.+&�WL3�����M��\��M=���.��,2�	��b_l��k�]�Kw�b��0; ��[���"�	lq?�k���6"�������~�;(��
-�&{�.��q���k��ʆ7��8����(ew ��D�Ѝ}�Ԑ�M��"���*��eV���Ӭ)t�gR�ЕmVi�N����utm�ա�{�H鿃�L�`^�7Pd^㭀n^�+Tl^c/+i��M���ȿ�O�}�������ǲ��\|���3�Tq� >[�
-���g�ذ���CJ�b�&%�Qp�A�	n��%���J01[�sY��1R������i�"�
-�Gk�r;�G
-��>��B���-�?D��B��G�Xײ��}4]����|��ğUh��VjM��3j�6Po�@�,��:i�4P)�r�2������������=}��pO�aV����_��s��%|�:ݡ4�U��W��*�����yJ�|%�auz�Ҽ@	����j�1S�GP�%�/����CW��nwcg�h�Ί�[��%���^
-���h��D>�Y�D�м�)�׺@�^�_h�����z�v�%��Q-%��u���P'��*u&^
-��cNL�4��m�_QZ�h,�E6�,�	cr��~�,��JR��Ë�g�:�Ϗ���u���4�KЂ�|ҐF�D�4/فz8Go�M!�[�S�U�N�	S<�X�y'�%�t[i#x�e�+-���k�$��L���/���E_���B,Jf�c��좻z*5�Q-N�W��he���,��.�[p�4o��h���vj�� }:�v��5�i�wtaW���m����~�C�?���uG����!v
-����}*Tzp=>��D��qټ
-4r��r��I.�v�
-M�6;-d���Z�t�f��bN����i���N��~� %�XP���c�c��\�2��oJ���ы2�*���ωu*�NŢF����3?���ܫU��u0�Ho�G�M��-��u"��&<�Nv&+T�<�@S���iF��['15������>��ؿ�dR����H�P`A+�D[�I⃙��M���)?���"h�N�C-���mǤ�K�7H]p��W��j��>���˿�7�
-�����
-�VL!v?C��}�"��e���m'Ij�$IB:�dՄ�-�g�����SM�8M)�L6ۏ3E�
-�?����r��N�v�K�������v�UT�� ��g���$�5(�\�Y��N��)��5�3#�t���gF�v�MKo��.�C˧T*u܉��=d��uL�)��VφR���I;(��Mt�2�'�MO�-�'����Բis�C��"�P:��v)��⢸_���sEqcS�3��g���Ԍ�8�E�aY�\�h-��
-1�Rj~0�zޯ��-��fu��
-.�n�����@1E�V�JjD�	*�FK��M��T
-��U���jХ�\��:�ܯ�AϤVDc���z�Ԏ�Q���`�r��ʽV)\�Y�)��;Q���)�y�(���_*��
-�����#j]Q�LD�/����6(�q�@t�=�Q�W��+������p���l����¯���̍og���T>.�	O�~�u�9��4�a��hnc4��Hj�����߃p53��W��ˎ\�9����07�B�ۨA��f�㰉W���^�j�g�<�j%b���y�_̎~1���NU���؂��=Nq��K7�\��co�e�=��>�4G�"ru���-���?v��0K�ԭ�.x{U�oGB���ҫ������`D�Yf�K�Ə{�]�ߩ�#�ep޻� ��	H�e-~M�l;	�k�j����A�b�~�xf#����u�(?.$���N��1���	�a���5鸯Ŏ��V��.?L��q���f�	ڮ�݄�M���i�^��*��.�:�
-�R�`\f��7�s���Od�(6�F)$s�5챉��Q8�x'd8?rs�6,��Be����Z��~����ɍ���$�g����8?�~�O�:
- /�W��Ja�������� ��
-��9P�����:��	�VL$M	���]D�Ì�E?[�":��_� �H�U IO�pL��4��oj���b ����D65qE�˕��l��1[�O]�
-��cE��� �I����p�QS3�q-�Z-��%T�~q�%�<��4�B������4�	{+>�Hh�G>�@�g�|&�[:Y�]8;>U\��\�i.ӫ5�%�K,}�-m�H���*���H��� �@>.�\��"mV�qVя�j��A��Zp�p �>�X5ߪ��fz=OP��FMhrA��E=�[���h���rd��:��k����rQ��ؿc%��^��"\���]�9��5ϩ�=�$ԯ�=�r�I�����1����X��!�19 R�ml���f�U���,j���>������!��_�D�Rڼ߀�S����BJ�Ω³�v^�6��	�,.�_6��}mLј�J�p\�Rt\���s\s��k�b��b��yq�/������oC����׊���'�������������eFǗ*bJ��*��d�i�d�_]����^�,�ۣ�Bm)�a(u2��kȿ뽿�t�
-J)[�3�bS��4E�t�s�9�����[�|-}EXqx�S����V�?���1�T�"�-�br1Z�^k/�;�|1?.J8����Ks~9�4J+�3~.���-\����țIڳ��v��n�>v�\�Sh"}����%��B��QȢ�v��x��L�,SD���gBRN�t�t���>Ջ� �r��C��n$E���8~�H!����t�\)�+z8�h(���`�!�qZ��� 
-�Z���
-ѠA�V�B�� BQ��~��B�@!S�BGm�R*�;h)�Q�ZTʼB)*J�?h)Y��lQ)
-�dQ��Z�yy8����T�KIw�3Z�ϧ{���ʴ�F`�T��k
-9��r�(G�X[ȱ�z9�
-a��]��q�V�>�o�X�/)��i���_�B���ٔ-������X>�d>�.��Mm��h�����Pw}ks���,���,������Ȍ�R|��b�G�bw��ȎOX4Z�m�9}���z�z���ݕk�.�r9om����7F�Fk�B��u��l��O��'\��T�ҩ��Э? s���A7�욢�];HϾB={�Z�����|��\���*�ʊB�4��9��Z��:�3+Ҍ���b������Ku7���#�VC�#�V�N�pn��ڥv����}�lGz����:�o�5B[,�)Jպ�Ic9~�)T���W�G���s#kҞ8ސ����Џ�7���M�ӾD���h���[K��z��J�J-�z�g]V���45�h�%��<��SǬ��6��F���_�H����[�W鯇댌���P��J�S�~� e��g�%�j�t�a\�迼�Ac�H�g����QRFm��CRG����|��Z�	�ˈxGD���Ȃ�D��b���X1iS{�
-�%jQ(�!H>�M���;YS�-2w���T���T`��T��A`KJu[4���� a��Vz��F������9eě	RD���3̯Q�wt J"~�
-q�{��`�����$iD�B'�7&�7��e��5����d"+�Cd�R��G����a0c���D��):1Pa��ټ�wX9�����Co���B �F���^6�oY���rIc��?��,�����Q	�t�7*ͯ(���W�k���5^i�sY+���6�o�@;���ٻj�*��V�*�I\���We7)�E-��t�����r�����)�Y�R���(�
-�>��q��~�23���'![lt���iF�r�F�`Y�4[)}��`W��Gj!��Qؕ��*�EW������]��
-���)�9�}�O�K���
-�/�y�)��}�O�˦�j5��1M�v�L\�"�'}2~bʸq��!-�}2~j��J���)�M����t�:5�4AIBuuNIFGRA�b��I�v&'�Մ��z����{ߧ㪒]9Nۉ�;�Nw3�`f��x d6`�cl�x�ԩB�m�y2�d@o�k�$d�����ǇN�q���^{^k�"�w'�=Ӥ���"���O��W_7d����x>��M.ĝJ�D*d����q���O���;����Jm�4͖�̖�g��S���F�TBdo%d��9)�Àu�����͉��|Z;��K\��강��&���˕��5)�x���Y�+�����[����ot�x�m
-+���M��
-�f��|ח	�[V�� ��\R�Ω�n��OUb�g���w:kO�&v��}�){�I��֌1t{�X͖�����Ƌ���C�5�
-'�Y��j�Ć����)%�����X��Ę���-�^9P��
-�5j�'�����E�5N��ƍg߇���QA:a_eӈ����m�l�fPnz���~����d?c~?��s~?5t�褳���6��pB 
-:5���f%�����,�P�nP�tP�jPt�sP��Aѿ����we�����Oz�&�Q��]4�]�y�;E���pƤi���z��#��إe�E�����M?�i��*E~,!{ܗx�fXs1��A�%�7��د��/�\r�/O���R#~_���h���V�0?k�,��_6,���k/ÚK�IQ�g%O��eW��dkI�DLO�vy�v��5��{��dIl���/\�kb;�*��p" 6�l�������(����$��.��6w�>`�+�R�G)�mu�)����Ǹaআ��%�f7m*��t�3�)�C���`�5ü��A7%��������a�>�ѽlr��Z�j����
-'�Y�� �9a6J�:;��Z��7��8�a����&�_�&[m6�\/��&�_�&;�lR�UlR���d�dK�M^ϲɱ�`���)6)�4D�nlR�u3�����&ǜ96,ӅMPs
-��&o�Mް�d��!6��J
-7{��;�x ��&�*3Aq*�x�RV
-%q(\�t�I~�r�����3pR�+��û��1�mJ�Ĵ�m�l�.��1�� 6-/��"�kS����nqƦ�m�z���x�w��ޑ
-k�v��.����d���Q���o���Udr%���r1��'��	I�l�W�S��M�p�i��fL����`������W��.N30��]2�)?2�l����|=�0������yv]O���G�\O���G�\��]QߜA}sO���:���P_�����x)�
-OcC��f����4\���a�}��[�mU�Wj���R{�g�޴R��_�Ys�d���T{Z�}�9�
-��Y������j#��,	;̎�U����ߡ�I,
-��T3��X��a�)r|H��ರ�H6����vio@�QX�o�a�stO�c�c�,]�7&o,B��������ƴ[0��e���?�f/;�¹�|x�
-T',�̓\�!�
-������"v�Σ�y;/���ɬ�-e�be���;J�;!n�,9���S(j�1,0��sM�^�V�<v FLAЖL.G�m�_� �2/��xe��b��@�\u�7j0	���KmZx�W��&�E���\%t�}�iA2W��J|�֣"U^F�����8��<\>5;'�C_G��	k��V-ki*��%�I	��m�z~V2�'�h��B
-��w�(4�W�-�(L�E߬�+J#oWI�Ƙ�/1���3�ٳ/��P�Ůc
-��z�br,띆��]�Nd�V�BÝ��>��Q�_�#�iP�}G�]���=�������~�ݩ�\���7��j�{��AcPk0��ςM�6���gA��PD�}�O���=ڙyY=�Y��\�K���g���&?
-�mD�c��v�պ�~Ν-��C�7��O�����.a�!:�����"
-��F��SF����짺ٷ�?��9�Ka�`;���CP�!�Q�)�3$�� �]�k|9���eX�C�>A?���[N�\L�\j����p�؆��L�Ã)AװWX�� {8+[B�aW�f-{o�K��R9s�vf�^V}.l9EƠ� +�@�(s��-wҽˍ���γ����%�\�K����j��"96�n��x��S�8�:].�T�� �V4�P+���+��^��{paS�5��vY�a��kR���3D�����p:�|W�8�"�>��\�?������|v��%ߗv������؎+���I�f����'ߘ��b�ѯ�qE8��oؾ⬺k	������uv�h�������������)��q��$|!;	�fO�#h���E^5l-̟���ű�q6(���Aq"h��퉓A�lO�
-_���A�tP+0O�3A�g�	g�Z�y6h�jE湠q>���ƅ�Vb^�Z�y1h\
-j��KA�rP�m^W��߼4��2�j��2���_�kA�¼4��>���q#�U�7�FgP��Ac����p��h��#c���5G*�(E�g�R�ъ4G+�ES�1�1V�Ts�b�S��9N1�+Z�9^1&(Z�9A1&*ڭ�DŘ�h��I�1Y�j�Ɋ1E�4s�bLU�Zs�b<�hu��1M���i�1]���tŘ�h��1S��3c��}˜��M7g+��V/s�	E����b�U��̹�1O����IE����b�W������@Ѿk.P����=s�b,R�;�E��XѾo.V�E��٢K���%��T�~h.U�e����e������b<�h?2�V�g���3����|V1�+�O�励B�~f�P����0W*F�B|Ъ�)��)�*���b<�P;?��j�Պ�t[�/ ����&/*�Zr8͵��N���u��^������9��K������x�?3_V������!n��Q�Ϳ(ƫJ��櫊�Iix�ܤ�)
-u���qH��tH1+ԑ+�t�#�qt?�ǔ�G�c�q\i��y\1N(
-�	f'��NX�?r4�0���c9�ɜ󴸴�(&o�Q��P��2QF�\n����ݎ0�"�C�2m�/�$��S0�`AI(�J�����#�Q>������o2��wR�_���Z�12�ü�Ώ���x����q���P�$�G�xV&`%K��H��8�ҸO����<��S��Jq����Y��+�~����0��)�%��r�Nw=�A��:��Q��g�#�{i����?�&��	q˼���z+qT*�j�H�U;*u`�0:(;� ��
-��"O"�~]�ǿ��| v�'�<�"��y�jy⛊<}s-O�yE��"?����,��( � ��l�p0'�U����jP
-���lV䔝���4�e�T����d��4�g���ey�e��=������
-E��"�������H#�Uo��H��\��	��\RqF:!�#���A�ZV��Vׅ���Ϲ��أ5ps�v���|�;1�����p����R`��Y���_�j�@ԟ�*���/��������V�sYb$���?S���z�Mw��P �P�`���Ӏ�����+����uyݥ��.�9lnE����s����r����|�(4/�/K�\>a��y=���i��"�*�'���J�{D�������\�Q�N~EEOwo��=��wN�����+��q>\�,��f�H��;Q�CR�܂^w���]�Eܝ�݈��pJ!���uH�a_яiB����@$���^.��h.`��R�Pβ�*gyY�0Z�|�/�[]3�;��B��U��A��muǊ����B�r���B*�V�6��b>;����[�J�=�vA�I����Q�X��~o�+��
-�� ��<=b���^8~�����邪����Jvi9p>$Ŷ��L�����@��p�b�_G���h���i���V�!�q�v8/���C����{"7�p�1�����%Aqk՞�( t�G���S�ma�#���(�np&���\mϿ2�uݓ/��zX��`�)b��V�;��W�S=3I�m7�"nض��N8�".dS`֖ PD21Vn��Ե���Y��Eһ������1@n�yថ��
-h=f+�#d�M!+o
-i!���i[d<���u�6se����*��
-;��*�J���
-
-�R҄S�ʍ���I�����0�vY��0V����o�[
-.�t�u��E"Ѣ�v�c���T��q�[	��	"�P�8��G���Q���t"2ޙxYK&���?�D���0O`@�?���^�=i4U���-60O�^����zU1!���
-E8U�#�.�.i���lOʢ1�f�kgK�g{��"=�!~���[�;�h�e��E(a$��˩�ðY[ ���I"(�^[�%(&�Y��[�����5�<�d^c�Tn�vFi����T�.6Y�A1c�\gN�A����{F�-�퀘V{�#����֠���`ʱvT/�I�1a�Dx{���Z�b{���`����0ɱ�o�����H:S��k+`�$Ӧ 0[4���zB����j�
-��Uw�nG�&w�&�y�����i3��Ǚ�z�M�h�u6��5ޖ��U\2��gڪ��C{�w)�NOd��a~g�PF@�//�ݷ�r��Y^ 
-��]g$W��ޖ��r�݅��&|q�؋U��QZc����XE��.c�𯭊��;�To��E�%�K��k��)�Б�V�fw�[�=���W� �v�M�����d���L�!���m�}KR��%��aǐ�x���e�n��S�Vq�c�*�ވU�
-�t e���n481l�M�U����C�L��,�r������`�d��Q;Ѧ�<����{)���̴�,����.�0�X���?[��8��)��:!�޴Нe@X\��¬�En��m���T<�*"2����m�u���XۙHM8��
-P�_�X�����@�Vb�By�z���3��?vH��X�����C%'�����P�����q2�(�;N�>�㋰�Pr�;�$Ǚ����8v����J�����Ѱ�B�ћ~.���c-\]�� ֘�"Vh4�Q�4�1Fhymu	ALj�w}@����G��x@��H�>���N�-r�?���A��(�t�W�Y�[�hZ��N� |L���U�)�J����.��!Mc�8Us��Tc��I�x՘�jNs�jLT5�9Q5&��ۜ��U�cNV�)��5���1ry\�0��v�X���j,�R��%kX�4�<�wf鐻��^������ߢ������q������G(�AY�k[`*�����T\�2d�}i��P���pbm����"�F�O���Uo*�X+�{���Zٟ��}�F�S��a����B�Ss��ma�BJ��Ҕ�y��K!ԡ�a_�%����b5)H�F' lHr�ɕ��f9�T�['G'"ɗ7��$e"Ifv%ة���IH��'!��l�Fo�Zc+:�/�ry�,�`�.�^-�5�>�Q�?��)�l2�ǝ���"�
-�ߺљj���@���G߸���a�$�A������(vnᵎ����޴@B���
-�u��W�j%��W����y�tQ���	������U�5�Oq�
-a\ѧ v*>[xT��w>��Ұ�1�{�>���.��f�����<������@�,��Fb�;��0��أ?/�}.\`R}^�s���3��,�g>�@�bT��%�>��h� S�O��4>�p��,�g>+�4���9S5f�4k�dAS
-��UY�.�GT��?j���2Y�v9����FV�u�"k���x|Rn��QUN�x�
-օ�����Ϩ˲���O����߲�ۣ�Ԍ����-Q3:��-V3:�x´E��ft:ݬ���9�k:;ݣ;;'wv���|��s
-o6v7yw�b�7c���xn�ZQڍj�0p��n�5�,�&�t�Ct���W�л'U��8Z��F'W��n��
-�^�2{��;����ns�w���ٯ��E�j<E!��#�>��DN%�~X�H�[4����s\:6e@���U������q��y|n��NA`���l�W&��u��P�����v�:d�r������[����.����[lp{\��ĞՃ�e�sn>�>���e�;:)B��U�^��H��ߧ#�� �q�ۙys�#���!|=8���ݱx���nS���<Wl*����){��P�����==�@XY<�o�ʱ�|,�TR�>U��[�%ܚ~oQ]R��5�����5�^���^��Ph���v �$��[��RS����d�c,���{
-���=�o/�m"����-�� f+~=u`��)T�CSPH$J��<xa"���y�������fFؓ�=v#�L��a��WF�����8ta�=��Ӫ�n��
-�P*s@�?ٕ:Ҷ�C�n�Q����`���'������N�S=4��{㻳���ӼM�4o���`0v�{�(^��Q8M*K�B�Q���W9���� ���Hj(������'݅�K��cM�zg�o���XO���ؐ�B!RM@َ!����N��c�6\
-F�J�B���Ԋ�J�Ȋ�z����*��9\
-$���<��Z:���	� �3՞���h��q�;�����\���ߖ��8b�Uc���V��JZˮT�VA�b��W���!��\%
-Ŏ���>e�Z6��LM�J�+�!�J$�M��I����V!�M��=}�R��t@���,�E�B�5�����wP��E1�c����X?�,�� �|��-��q.�Fl_,ͱ�����8/�!â1'���NLp���EKͶ�Q�h�z�d2�N� �����r��:�f�ܸJ���Qp�Q�]@ҽ���1��Ƶ�ݥ�q�L��rG;�T���ƽ��{�c�帷�LnȞc���l�-oy���ȣg��ZX%�Řۓ�N�<6����TTZ[.Th����i��U�y��RG�{N­uR'�������{8�m�G
-�e�1^��2�<'ø _�P'9*'�" ��(-C����EU9�f� ��W�o����
-"/���P)�Q1��9V��Kv�8��B#��	�L����6"��r(о�6z��0+ $��jةL��ɒ��=^�S��P�Q�����vËZAݢ
-
-7m,�*��	������-I\`��!ᤜ�6;!?V��������a����6��p\��I>!ӹ _]�Q%�2�s�ʍ�T����rm�̋�?2��1e���Y���Ƴ�:�gP���|��t����.g���1t+�di�<�%THΖ[K`��\��bG[�rb� [	�6a�0i!��i �v�!K�����شB��]��"V䃰�y���p\�#��0~����$���A��X���e��/Yy9$iR�����V�d D{)�hj�����r�'�g��˫���=~FRƅ849e�%p��$A�9Ħ~�b~�<��+�p��7O"`eUV��������-O�I�*�p�v��S/�y�*sZ1k@���<lv磳����F�BG���?~���=b>�<��C�����ņ}`�{�Wp߯rᎊ���l~h��������|���C�������_�T���2����q_3�=�p����k&ם��ѡ�
\ No newline at end of file
diff --git skin/adminhtml/default/default/xmlconnect/boxes.css skin/adminhtml/default/default/xmlconnect/boxes.css
index fdf259f..63c7508 100644
--- skin/adminhtml/default/default/xmlconnect/boxes.css
+++ skin/adminhtml/default/default/xmlconnect/boxes.css
@@ -90,6 +90,7 @@
 .image-item-upload .uploader .progress,
 .image-item-upload .uploader .complete,
 .image-item-upload .uploader .error { display:block; height:100px; text-align:center; }
+.image-item-upload .uploader .progress,
 .image-item-upload .uploader .complete { text-align:center; line-height:95px; }
 .image-item-upload .uploader .file-row-info img { vertical-align:bottom; }
 .image-item-upload .uploader .file-row-narrow { margin:0; width:140px; }
diff --git skin/adminhtml/default/enterprise/boxes.css skin/adminhtml/default/enterprise/boxes.css
index 78491aa..f9db5c9 100644
--- skin/adminhtml/default/enterprise/boxes.css
+++ skin/adminhtml/default/enterprise/boxes.css
@@ -1508,8 +1508,6 @@ ul.super-product-attributes { padding-left:15px; }
 .uploader .file-row-info .file-info-name  { font-weight:bold; }
 .uploader .file-row .progress-text { float:right; font-weight:bold; }
 .uploader .file-row .delete-button { float:right; }
-.uploader .buttons { float:left; }
-.uploader .flex { float:right; }
 .uploader .progress { border:1px solid #f0e6b7; background-color:#feffcc; }
 .uploader .error { border:1px solid #aa1717; background-color:#ffe6de; }
 .uploader .error .progress-text { padding-right:10px; }