export default {

    setupComponent(args, component) {
        component.set('test', 'hello');
    },

    shouldRender(args, component) {
        return component.siteSettings.devlog_categories_enabled;
    },

    actions: {
        myAction() {
            console.log('my action triggered');
        }
    }
}