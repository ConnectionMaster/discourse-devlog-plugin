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

    add_to_serializer(:topic_view, :devlog_enabled, false) do
      object.topic.category.custom_fields['devlog_enabled']
    end

    add_to_serializer(:topic_view, :can_create_devlog_post, false) do
      first_poster = object.topic.posts[0].user_id
      current_user = scope.user.id
      object.topic.category.custom_fields['devlog_enabled'] && first_poster == current_user
    end

    add_to_serializer(:post, :devlog_post, false) do
      object.custom_fields['devlog_post']
    end

    Post.class_eval do
      after_save do
        post = self
        if topic.category.custom_fields['devlog_enabled'] && post.reply_to_post.blank? then
          DistributedMutex.synchronize("devlog-#{post.id}") do
            post.custom_fields['devlog_post'] = true
            post.save_custom_fields(true)
          end
        end
      end
    end

  end
end