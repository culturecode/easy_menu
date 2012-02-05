$(document).ready(function() {
    // Because some browsers don't support submit buttons outside of forms triggering form submits,
    // do it in javascript just to make sure it happens
    $('input[type=submit][form]').live('click', function(){
        if (form = document.getElementById(this.getAttribute('form'))) {
            // If the form is already submitting, we want don't want to submit it again.
            if ($(form).hasClass('submitting')) {
                return false;
            }

            var tempCommit = $("<input type='submit' name='commit' style='display:none'>");
            tempCommit.attr('value', $(this).attr('value'));
            form.appendChild(tempCommit[0]);
            tempCommit.click();
            return false;
        }
    });
    // Used by the above click handler to determine if the browser already submitted the form.
    $('form').submit(function() {
        $(this).addClass('submitting');
    });

    // Allow users to open an close menus by clicking
    $('.menu_bar_content.with_menu').removeClass('no_js');
    $('.menu_bar_content.with_menu .menu_bar_item').click(function(){
        var mbc = $(this).closest('.menu_bar_content');
        $('.menu_bar_content.with_menu').not(mbc).removeClass('open');
        mbc.toggleClass('open');
        return false;
    });
    $('body').click(function(){
        $('.menu_bar_content.with_menu').removeClass('open');
    });

    // Disable Elements with a disable condition when that condition is met
    $('.menu_bar_item[data-disable-event-element]').each(function(){
        var mbi = $(this);
        var observableElement = eval(mbi.getAttribute('data-disable-event-element'));
        var event = mbi.getAttribute('data-disable-event');
        var condition = mbi.getAttribute('data-disable-condition') || true;

        var setState = function(){
            if (eval(condition)){
                mbi.addClass('disabled');
            } else {
                mbi.removeClass('disabled');
            }  
        }

        // Init the current state and bind the observer
        if (observableElement && event){
            setState();
            observableElement.bind(event, setState);
        }
    });
});