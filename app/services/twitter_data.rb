module TwitterData
  class User
    include TwitterAPIClient

    def initialize(user)
      @user = user
    end

    def call
      avatar = twitter_data.profile_image_url_https
      avatar_url = avatar.scheme + '://' + avatar.host + avatar.path
      { name: twitter_data.name, screen_name: twitter_data.screen_name,
        description: twitter_data.description, avatar_url: avatar_url }
    end

    private

    attr_reader :user

    def twitter_data
      @twitter_data ||= client(user).user(user_id: user.twitter_id)
    end
  end

  class UserTweets
    include TwitterAPIClient

    def initialize(user, tag_name, since_id = nil)
      @tweet_ids = []
      @tweeted_ats = []
      @user = user
      @tag_name = tag_name
      @since_id = since_id
    end

    # return [["<a href=\"https://twitter.com/hashtag/%E3%83%86%E3%82%B9%E3%83%88?src=hash&amp;ref_src=twsrc%5Etfw\">#テスト</a>", 2020-04-13 07:13:39 UTC, 1249596597479956481],
    #         ["あ<a href=\"https://twitter.com/hashtag/%E3%83%86%E3%82%B9%E3%83%88?src=hash&amp;ref_src=twsrc%5Etfw\">#テスト</a>", 2020-04-12 01:54:07 UTC, 1249153794946011137]]
    def call(type = 'standard')
      case type
      when 'standard'
        standard_search
      when 'premium'
        premium_search
      when 'everyday'
        everyday_search
      end
      client(user).oembeds(tweet_ids, omit_script: true, hide_thread: true, lang: :ja)
                  .take(100)
                  .map do |oembed|
        oembed.html =~ %r{\" dir=\"ltr\">(.+)</p>}
        $+
      end.zip(tweeted_ats, tweet_ids)
    end

    private

    attr_reader :user, :tag_name, :since_id, :tweet_ids, :tweeted_ats

    def standard_search
      @standard_search ||= begin
        client(user).search("##{tag_name} from:#{user.screen_name} exclude:retweets",
                            result_type: 'recent', count: 100).take(100).each do |result|
          tweeted_ats << result.created_at
          tweet_ids << result.id
        end
      end
    end

    def premium_search
      @premium_search ||= begin
        client(user).premium_search("##{tag_name} from:#{user.screen_name}",
                                    { maxResults: 100 },
                                    { product: '30day' }).take(100).each do |result|
          next if result.retweeted_status.present?

          tweeted_ats << result.created_at
          tweet_ids << result.id
        end
      end
    end

    def everyday_search
      @everyday_search ||= begin
        client(user).search("##{tag_name} from:#{user.screen_name} exclude:retweets",
                            result_type: 'recent', since_id: since_id).take(100).each do |result|
          tweeted_ats << result.created_at
          tweet_ids << result.id
        end
      end
    end
  end
end
