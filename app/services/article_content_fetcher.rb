class ArticleContentFetcher
  Result = Struct.new(:success?, :body, :title, :error_message, keyword_init: true)

  def initialize(url)
    @url = url
  end

  def call
    fetch_result = ArticleHtmlFetcher.new(@url).call
    return error_result(fetch_result.error_message) unless fetch_result.success?

    extract_result = ArticleBodyExtractor.new(fetch_result.html, url: @url).call
    return error_result(extract_result.error_message) unless extract_result.success?

    preprocess_result = TypingTextPreprocessor.new(extract_result.body).call
    return error_result(preprocess_result.error_message) unless preprocess_result.success?

    success_result(body: preprocess_result.body, title: extract_result.title)
  end

  private

  def success_result(body:, title:)
    Result.new(success?: true, body: body, title: title, error_message: nil)
  end

  def error_result(message)
    Result.new(success?: false, body: nil, title: nil, error_message: message)
  end
end
