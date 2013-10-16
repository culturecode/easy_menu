$(document).observe('dom:loaded', function() {
    var menuBarRootSelector = '.menu_bar:not(.no_js) ';

    // Because some browsers don't support submit buttons outside of forms triggering form submits,
    // do it in javascript just to make sure it happens
    Element.on(document.body, 'click', 'input[type=submit][form]', function(event){
        var element = event.element();
        if (form = document.getElementById(element.getAttribute('form'))) {
            event.stop();
            // If the form is already submitting, we want don't want to submit it again.
            if ($(form).hasClassName('submitting')) {
                return;
            }

            var tempCommit = new Element('input', {type:'submit', name:'commit', style:'display: none', 'value':element.getAttribute('value')});
            form.appendChild(tempCommit[0]);
            tempCommit.click();
        }
    });
    // Used by the above click handler to determine if the browser already submitted the form.
    $$('form').invoke('observe', 'submit', function(event) { event.element().addClassName('submitting') });

    // Allow users to open an close menus by clicking
    $$(menuBarRootSelector + '.menu_bar_content.with_menu').invoke('removeClassName', 'no_js');
    $$(menuBarRootSelector + '.menu_bar_content.with_menu .menu_bar_item').invoke('observe', 'click', function(event){
        var mbc = $(event.element()).up('.menu_bar_content');
        $$('.menu_bar_content.with_menu').without(mbc).invoke('removeClassName', 'open');
        mbc.toggleClassName('open');
    });
    Element.observe(document.body, 'click', function(event){
        if (event.findElement('.menu_bar_content.with_menu .menu_bar_item')){ return }  // Don't close the menus if the click came from a menu trigger
        $$(menuBarRootSelector + '.menu_bar_content.with_menu.open').invoke('removeClassName', 'open');
    });

    // Disable Elements with a disable condition when that condition is met
    $$(menuBarRootSelector + '.menu_bar_item[data-disable-event-element]').each(function(element){
        var mbi = $(element);
        var observableElement = eval(mbi.getAttribute('data-disable-event-element'));
        var event = mbi.getAttribute('data-disable-event');
        var condition = mbi.getAttribute('data-disable-condition') || true;

        function setState(){
            if (eval(condition)){
                mbi.addClassName('disabled');
            } else {
                mbi.removeClassName('disabled');
            }
        }

        // Init the current state and bind the observer
        if (observableElement && event){
            setState();
            $(observableElement).observe(event, setState);
        }
    });
});
