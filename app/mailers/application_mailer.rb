class ApplicationMailer < ActionMailer::Base
  default from: RailsIdentity::MAILER_EMAIL
  layout 'mailer'
end
