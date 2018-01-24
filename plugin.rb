# name: devlog-categories
# about: A plugin for tracking and managing devlog posts
# version: 0.0.1
# authors: Mikael Säker

enabled_site_setting :devlog_categories_enabled

PLUGIN_NAME = "discourse_devlog".freeze

after_initialize do

  if SiteSetting.devlog_categories_enabled then

    module ::DiscourseDevlog
      class Engine < ::Rails::Engine
        engine_name PLUGIN_NAME
        isolate_namespace DiscourseDevlog
      end
    end

    Category.register_custom_field_type('devlog_enabled', :boolean)
    Post.register_custom_field_type('devlog_post', :string)

    TopicList.preloaded_custom_fields << "devlog_enabled"

    add_to_serializer(:topic_list, :devlog_enabled, false) do
      category_id = object.topics[0].category_id
      category = Category.find_by_id(category_id)
      category.custom_fields['devlog_enabled']
    end

    add_to_serializer(:topic_view, :devlog_enabled, false) do
      object.topic.category.custom_fields['devlog_enabled']
    end

    add_to_serializer(:topic_view, :can_create_devlog_post, false) do
      first_poster = object.topic.first_post.user_id
      current_user = scope.user.id
      object.topic.category.custom_fields['devlog_enabled'] && first_poster == current_user
    end

    add_to_serializer(:post, :devlog_post, false) do
      object.custom_fields['devlog_post']
    end

    require_dependency "application_controller"

    class DiscourseDevlog::UpdateController < ::ApplicationController
      requires_plugin PLUGIN_NAME

      def setdevlogpost(post_id, value)
        post = Post.find_by(id: post_id)
        DistributedMutex.synchronize("devlog-#{post.id}") do
          post.custom_fields['devlog_post'] = value
          post.save_custom_fields(true)
          render json: { post_id => value }
        end
      end

      def setpost
        post_id   = params.require(:post_id)
        setdevlogpost(post_id, 'post')
      end

      def setreply
        post_id   = params.require(:post_id)
        setdevlogpost(post_id, 'reply')
      end
    end

    DiscourseDevlog::Engine.routes.draw do
      put ":post_id/setpost" => 'update#setpost'
      put ":post_id/setreply" => 'update#setreply'
    end

    Discourse::Application.routes.append do
      mount ::DiscourseDevlog::Engine, at: "devlog-post"
    end
  end
end