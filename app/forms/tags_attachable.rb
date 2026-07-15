module TagsAttachable
  def self.included(base)
    base.validate :tag_names_are_valid
  end

  private

  def attach_tags(article, clear_blank: false)
    return if tag_names.nil?
    return if tag_names.blank? && !clear_blank

    tags = normalized_tag_names.map { |name| find_or_create_tag(name) }
    # 同一記事の同時更新による中間テーブルの一意制約違反を防ぐ。
    article.with_lock { article.tags = tags }
  end

  def tag_names_are_valid
    return if tag_names.blank?
    return unless normalized_tag_names.any? { |name| name.length > 20 }

    errors.add(:tag_names, "は1件あたり20文字以内で入力してください")
  end

  def normalized_tag_names
    tag_names.to_s.split(",").map(&:strip).reject(&:blank?).uniq
  end

  def find_or_create_tag(name)
    Tag.transaction(requires_new: true) do
      Tag.find_or_create_by!(name: name)
    end
  rescue ActiveRecord::RecordNotUnique
    Tag.find_by!(name: name)
  rescue ActiveRecord::RecordInvalid => error
    raise unless uniqueness_conflict?(error.record, :name)

    Tag.find_by!(name: name)
  end

  def copy_record_errors(record)
    record.errors.full_messages.each { |message| errors.add(:base, message) }
  end

  def uniqueness_conflict?(record, attribute)
    record.errors.details.fetch(attribute, []).any? { |detail| detail[:error] == :taken }
  end
end
