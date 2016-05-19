# github rapid board

Easily track and manage issues that span multiple repos.

Still under construction.

### Local Development

 * `bundle exec rails s`
 * `bundle exec rake github:sqs_import`

##### To see github request trace

Run the server with `DEBUG=true`.  This trggers the Faraday request logging [built into the github_api gem](https://github.com/piotrmurach/github/blob/4b2435e993e62712f61b913540118325145bfcce/lib/github_api/middleware.rb#L21).