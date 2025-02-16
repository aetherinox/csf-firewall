<iframe border="0" name='myiframe' id='myiframe' src="/nodeworx/configservercsf" style="width: 100%;" frameborder="0" onload="resizeIframe(this);"></iframe>
{literal}
<script>
  function resizeIframe(obj) {
    obj.style.height = obj.contentWindow.document.body.scrollHeight + 'px';
	window.scrollTo(0,0);
  }
  window.parent.parent.scrollTo(0,0);
</script>
{/literal}
