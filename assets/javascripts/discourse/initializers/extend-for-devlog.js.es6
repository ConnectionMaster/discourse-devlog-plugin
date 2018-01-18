import { withPluginApi } from 'discourse/lib/plugin-api';

function initializeDevlog(api) {

  api.includePostAttributes('devlog_post');

  api.decorateWidget('post:after', function (dec) {
    var post = dec.getModel();
    return "Hello" + post.devlog_post;
  });

  api.modifyClass('controller:topic', {
    actions: {
      postDevlog() {
        console.log('devlog triggered');
      }
    }
  });

//      setupComponent(args, component) {
//        component.set('test', args);
//       //component.siteSettings.devlog_categories_enabled);
//      },
//
//      shouldRender(args, component) {
//        return component.siteSettings.devlog_categories_enabled;
//      },
//
//      actions: {
//        myAction() {
//          console.log('my action triggered');
//        }
//      }
//  });

};

export default {
  name: "extend-for-devlog",

  initialize() {
    withPluginApi('0.8.7', initializeDevlog);
  }
};