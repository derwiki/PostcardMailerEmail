require "test_helper"

class CommandMailerTest < ActionMailer::TestCase
  test "adduser" do
    user = users(:one)
    new_address = addresses(:one)
    mail = CommandMailer.adduser(user, "ned.flanders@springfield.com", "Add User", "from@example.com", new_address)
    assert_equal "Re: Add User", mail.subject
    assert_equal ["ned.flanders@springfield.com"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "We've added", mail.body.encoded
  end

  test "signup" do
    user = users(:one)
    mail = CommandMailer.signup(user, "Sign Up", "from@example.com")
    assert_equal "Re: Sign Up", mail.subject
    assert_equal ["ned.flanders@springfield.com"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_equal ["postcardmailer@kgk.host"], mail.bcc
    assert_match "Welcome to PostcardMailer.us", mail.body.encoded
  end

  test "verified" do
    user = users(:one)
    mail = CommandMailer.verified(user, "from@example.com")
    assert_equal "Re: Your PostcardMailer.us Account", mail.subject
    assert_equal ["ned.flanders@springfield.com"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Great news!", mail.body.encoded
  end

  test "error" do
    mail = CommandMailer.error("ned.flanders@springfield.com", "Error", "Something went wrong", "from@example.com")
    assert_equal "Re: Error", mail.subject
    assert_equal ["ned.flanders@springfield.com"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "Something went wrong", mail.body.encoded
  end

  test "help" do
    mail = CommandMailer.help("ned.flanders@springfield.com", "Help", "from@example.com")
    assert_equal "PostcardMailer.us - How to Use Our Service", mail.subject
    assert_equal ["ned.flanders@springfield.com"], mail.to
    assert_equal ["from@example.com"], mail.from
    assert_match "WELCOME TO POSTCARDMAILER.US", mail.body.encoded
  end
end 