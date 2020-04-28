class RegisteredTag < ApplicationRecord
  has_many :tweets, dependent: :destroy
  belongs_to :user
  belongs_to :tag

  validates :tweeted_day_count, presence: true
  validates :privacy, presence: true
  validates :remind_day, presence: true
  validates :tag_id, uniqueness: { scope: :user_id, message: 'を既に登録しています' }

  enum privacy: { published: 0, closed: 1, limited: 2 }

  def create_tweets(type = 'standard')
    client = TwitterAPI::Client.new(user, tag.name)
    client.tweets_data(type).each do |oembed, tweeted_at, tweet_id|
      tweets.create!(oembed: oembed, tweeted_at: tweeted_at, tweet_id: tweet_id)
    end
  end

  # cron処理用
  def add_tweets
    last_tweet = tweets.desc.first
    return create_tweets unless last_tweet
    # return if last_tweet.tweeted_at > Date.yesterday
    since_id = last_tweet.tweet_id.to_i
    client = TwitterAPI::Client.new(user, tag.name, since_id)
    client.tweets_data('everyday').each do |oembed, tweeted_at, tweet_id|
      tweets.create(oembed: oembed, tweeted_at: tweeted_at, tweet_id: tweet_id)
    end
    # return if client.tweets_data('everyday').empty?

    fetch_data
    Rails.logger.info("#{user.screen_name}の#{tag.name}にツイートを追加")
  end

  def fetch_data
    self.first_tweeted_at = tweets.last.tweeted_at
    self.last_tweeted_at = tweets.first.tweeted_at
    self.tweeted_day_count = tweets.group_by { |tweet| tweet.tweeted_at.to_date }.count # TODO: スコープにしたい
  end
end
