$(document).ready(function() {
    var menuBarRootSelector = '.menu_bar:not(.no_js) ';

    // Because some browsers don't support submit buttons outside of forms triggering form submits,
    // do it in javascript just to make sure it happens
    $(document).on('click', 'input[type=submit][form]', function(){
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

    // Allow users to open and close menus by clicking
    $(menuBarRootSelector + '.menu_bar_content.with_menu').removeClass('no_js');
    $(menuBarRootSelector + '.menu_bar_content.with_menu .menu_bar_item').click(function(){
        var mbc = $(this).closest('.menu_bar_content');
        $(menuBarRootSelector + '.menu_bar_content.with_menu').not(mbc).removeClass('open');
        mbc.toggleClass('open')
          .find('.menu').trigger('opened')
    });

    // Close the menu when the user clicks or there is a form submission
    $(document).on('click submit', function(event) {
        // Don't close the menu if the click was on a menu_bar_item. This case is handled by the previous event handler
        if ($(event.target).closest('.menu_bar_content.with_menu .menu_bar_item').length > 0) { return }

        // Don't close if we clicked inside a menu but not on a menu_item
        if ($(event.target).closest('.menu').length > 0 && $(event.target).closest('.menu_item').length === 0) { return }

        $(menuBarRootSelector + '.menu_bar_content.with_menu.open')
          .removeClass('open')
          .find('.menu').trigger('closed')
    });

    // Disable Elements with a disable condition when that condition is met
    $(menuBarRootSelector + '.menu_bar_item[data-disable-event-element]').each(function(){
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
