# Be sure to restart your server when you modify this file.

# Define an application-wide content security policy.
# See the Securing Rails Applications Guide for more information:
# https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
     policy.default_src :self
     policy.font_src    :self
     policy.img_src     :self, :data
     policy.object_src  :none
     policy.script_src  :self, "https://cdn.jsdelivr.net"
     policy.style_src   :self, :unsafe_inline
     policy.connect_src :self, "https://cdn.jsdelivr.net"
     policy.form_action :self, "https://github.com", "https://accounts.google.com"
  #     # Specify URI for violation reports
  #     # policy.report_uri "/csp-violation-report-endpoint"
end
   #
   #   # Generate session nonces for permitted importmap, inline scripts, and inline styles.
   config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s }
   config.content_security_policy_nonce_directives = %w[script-src]
  #
  #   # Report violations without enforcing the policy.
  #   # config.content_security_policy_report_only = true
end
