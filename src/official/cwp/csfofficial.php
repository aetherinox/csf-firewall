<iframe scrolling='auto' name='myiframe' id='myiframe' src='loader_ajax.php?ajax=csfframe' frameborder='0' width='100%' onload='resizeIframe(this);'></iframe>
<script>
function resizeIframe(obj) {
 obj.style.height = obj.contentWindow.document.body.scrollHeight + 'px';
 window.scrollTo(0,0);
 window.parent.scrollTo(0,0);
 window.parent.parent.scrollTo(0,0);
}
</script>
