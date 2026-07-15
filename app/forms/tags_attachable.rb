module TagsAttachable
  def self.included(base)
    base.validate :tag_names_are_valid
  end

  private

  def attach_tags(article)
    return if tag_names.blank?

    names = normalized_tag_names
    tags = names.map { |name| Tag.find_or_create_by!(name: name) }
    article.tags = tags
  end

  def tag_names_are_valid
    return if tag_names.blank?
    return unless normalized_tag_names.any? { |name| name.length > 20 }

    errors.add(:tag_names, "は1件あたり20文字以内で入力してください")
  end

  def normalized_tag_names
    tag_names.to_s.split(",").map(&:strip).reject(&:blank?).uniq
  end
end
