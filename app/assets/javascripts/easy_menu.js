$(document).ready(function() {
    // Because some browsers don't support submit buttons outside of forms triggering form submits,
    // do it in javascript just to make sure it happens
    $('input[type=submit][form]').click(function(){
        if (form = document.getElementById(this.getAttribute('form'))){
            form.submit();
            return false;
        }
    });                    
});