# name: devlog-categories
# about: A plugin for tracking and managing devlog posts
# version: 0.0.1
# authors: Mikael Säker

enabled_site_setting :devlog_categories_enabled

after_initialize do
  require_dependency 'basic_category_serializer'
  require_dependency 'category'
  require_dependency 'topic'

#  class ::BasicCategorySerializer
#    attributes :devlog_posting
#
#    def include_devlog_posting?
#      Category.devlog_posting?(object.id)
#    end
#
#    def devlog_posting
#      true
#    end
#  end

  require_dependency 'topic_view_serializer'
  class ::TopicViewSerializer
    attributes :my_attrib

    def include_my_attrib?
      true
    end

    def my_attrib
      "howdythere"
    end
  end


  class ::Category
      def self.devlog_posting?(category_id)
         category = Category.find(category_id)
         return category.custom_fields["devlog_posting"]
      end
  end
#
#
#  class ::Topic
#    def devlog_posting?
#      SiteSetting.devlog_categories_enabled && 
#        Category.devlog_posting?(category_id) && 
#        category.topic_id != id
#    end
#  end
end

