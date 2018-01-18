# name: devlog-categories
# about: A plugin for tracking and managing devlog posts
# version: 0.0.1
# authors: Mikael Säker

enabled_site_setting :devlog_categories_enabled

after_initialize do

  if SiteSetting.devlog_categories_enabled then

    Category.register_custom_field_type('devlog_enabled', :boolean)
    Post.register_custom_field_type('devlog_post', :boolean)

    TopicList.preloaded_custom_fields << "devlog_enabled"

    add_to_serializer(:topic_view, :devlog_enabled) {
      object.topic.category.custom_fields['devlog_enabled']
    }

    add_to_serializer(:topic_view, :can_create_devlog_post) {
      first_poster = object.topic.posts[0].user_id
      current_user = scope.user.id
      object.topic.category.custom_fields['devlog_enabled'] && first_poster == current_user
    }

    require_dependency 'post_serializer'
    class ::PostSerializer
      attributes :devlog_post

      def include_devlog_post?
        object.topic.category.custom_fields['devlog_enabled']
      end

      def devlog_post
        if object.custom_fields['devlog_post'].nil? then
          false
        else
          object.custom_fields['devlog_post']
        end
      end
    end
  end
end

