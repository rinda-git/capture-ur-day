require "test_helper"

class JournalsControllerTest < ActionDispatch::IntegrationTest
# Deviseのログイン用メソッドをテストで使えるようにする
include Devise::Test::IntegrationHelpers

setup do
  # ① テスト用のユーザーをfixturesから取得する
  @user = users(:one)
  # ② そのユーザーでログインする
  sign_in @user
  # ③ テスト用のジャーナルをfixturesから取得する
  @journal = journals(:one)
end

  test "should get index" do
    get journals_url
    assert_response :success
  end

  test "should get show" do
    get journal_url(@journal)
    assert_response :success
  end

  test "should get new" do
    get new_journal_url
    assert_response :success
  end

  test "should create journal" do
  # OpenAI APIをモック化（実際には呼ばない）
  mock_result = {
    "rewritten_text" => "This is a test.",
    "notes" => [
      {
        "original_text" => "I went school",
        "corrected_text" => "I went to school",
        "mistake_type" => "grammar",
        "explanation" => "場所へ行く場合は go to + 場所を使います",
        "learning_points" => {
          "label" => "前置詞 to の抜け",
          "pattern" => "go to + 場所",
          "review_tag" => "preposition"
        }
      }
    ]
  }

  # OpenAI::Clientのchatメソッドを差し替える
  mock_response = {
    "choices" => [
      { "message" => { "content" => mock_result.to_json } }
    ]
  }

  mock_client = Minitest::Mock.new
  mock_client.expect(:chat, mock_response, parameters: Hash)

 OpenAI::Client.stub(:new, mock_client) do
    assert_difference([ "Journal.count", "Mistake.count" ]) do
      post journals_url, params: {
        journal: {
          body:        "Test body",
          tone:        "standard",
          mood:        "good",
          posted_date: Date.today,
          title:       "Test title"
        }
      }
    end
    assert_redirected_to journal_url(Journal.last)
    assert_equal(
      {
        "label" => "前置詞 to の抜け",
        "pattern" => "go to + 場所",
        "review_tag" => "preposition"
      },
      Mistake.last.learning_points
    )
  end
end

  test "should get edit" do
    get edit_journal_url(@journal)
    assert_response :success
  end

  test "should update journal" do
    patch journal_url(@journal), params: {
          journal: {
            posted_date: @journal.posted_date,
            mood: @journal.mood,
            title: "updated",
            body: @journal.body,
            tone: "standard"
            } }
    assert_response :redirect
  end

  test "should destroy journal" do
    assert_difference("Journal.count", -1) do
      delete journal_url(@journal)
    end
    assert_response :redirect
    end
end
