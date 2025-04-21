# Preview all emails at http://localhost:3000/rails/mailers/postcard_lifecycle_mailer
class PostcardLifecycleMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/postcard_lifecycle_mailer/status_update
  def status_update
    PostcardLifecycleMailer.status_update
  end
end
