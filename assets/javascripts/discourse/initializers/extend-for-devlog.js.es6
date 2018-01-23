import Quote from 'discourse/lib/quote';
import Composer from 'discourse/models/composer';
import Post from 'discourse/models/post';
import property from 'ember-addons/ember-computed-decorators';
import { ajax } from 'discourse/lib/ajax';
import { popupAjaxError } from 'discourse/lib/ajax-error';
import { withPluginApi } from 'discourse/lib/plugin-api';

function initializeDevlog(api) {

  api.includePostAttributes('devlog_post');

  api.decorateWidget('post:after', function (dec) {
    var post = dec.getModel();
    return "Hello" + post.devlog_post;
  });

  api.modifyClass('model:composer', {

    devlog_posting: function() {
      var reply = this.get('devlogPosting');
      if(this.get('devlogPosting')) {
        return '<h2>New devlog post</h2>';
      }
      return reply;
    }.property('devlogPosting'),
  });

  api.modifyClass('controller:composer', {
    actions: {
        save() {
          console.log(this);
          var t = this.save();
          t.then(function () { console.log("done!"); });
          console.log("yada!");
        }
    }
  });

  api.modifyClass('controller:topic', {

    updateDevlog(post, method) {
      const refresh = () => this.get("model.postStream").refresh();
      return ajax("/devlog-post/" + post.get("id") + "/" + method, { type: "PUT" })
        .then(refresh)
        .catch(popupAjaxError);
    },

    actions: {
      postDevlog(post) {
        this.replyToPost(post);
        composerController.set('model.devlogPosting', 'true');
        return false;
      },

      setDevlog(post) {
        return this.updateDevlog(post, "set");
      },

      clearDevlog(post) {
        return this.updateDevlog(post, "clear");
      }
    }
  });

};

export default {
  name: "extend-for-devlog",

  initialize() {
    withPluginApi('0.8.15', initializeDevlog);
  }
};