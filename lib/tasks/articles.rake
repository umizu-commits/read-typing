namespace :articles do
  desc "expires_at を過ぎた Article レコードを削除する"
  task cleanup_expired: :environment do
    deleted_count = Article.expired.count
    Article.cleanup_expired!
    puts "Deleted #{deleted_count} expired articles"
  end
end
