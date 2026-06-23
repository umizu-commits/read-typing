module TagsAttachable
  private

  def attach_tags(article)
    return if tag_names.blank?

    names = tag_names.split(",").map(&:strip).reject(&:blank?).uniq
    tags = names.map { |name| Tag.find_or_create_by!(name: name) }
    article.tags = tags
  end
end
