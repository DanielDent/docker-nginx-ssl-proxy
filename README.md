# SSL Front-End Proxy With Automatic Free Certificate Management

Zero configuration required - set up SSL in 30 seconds. Out of the box A rating at SSL labs. HTTP/2 enabled for increased performance.

This image contains nginx along with some glue code to automatically obtain and renew a free DV SSL certificate from [Let's Encrypt](https://letsencrypt.org/).

It is configured by setting two environment variables:
   * `UPSTREAM` - The IP address or hostname (and optional port) of the upstream server to proxy requests towards.
   * `SERVERNAME` - The hostname to listen to. The system will automatically obtain an SSL certificate for this hostname.

An optional `EXTRANAMES` variable can be provided with a list of additional domains to request as subject-alternative-names for the certificate.

Certificates from Let's Encrypt are issued with a 90 day expiration. This image will automatically renew the certificate when it is 60 days old.

Prior versions of this image used simp_le. It has been changed to use certbot due to reliability issues with simp_le.

## WARNING

This image's default configuration includes a String-Transport-Security header with expiry set to 18 weeks (~ 4 months). Visitors' browsers will cache this header for 6 months and will refuse to connect except over SSL.

Eventually, you may wish to:  
   * Increase the header's expiration time.
   * Have your domain included in browser [HSTS Preload](https://hstspreload.appspot.com/) lists.

## Example Use (via docker-compose)

Create a docker-compose.yml file as follows:

    nginx-ssl-proxy:
      image: danieldent/nginx-ssl-proxy
      restart: always
      environment:
        UPSTREAM: 127.0.0.1:8080
        SERVERNAME: test.example.com
        EXTRANAMES: www.test.example.com,test2.example.com
      ports:
        - "80:80"
        - "443:443"
      volumes:
        - "/etc/letsencrypt"

Then simply `docker-compose up`.

## Certificate Data

A `/etc/letsencrypt` volume is used to maintain certificate data. An `account_key.json` file holds the key to your Let's Encrypt account - which provides a convenient way to revoke a certificate.
 
## Customizing

Nginx configuration can be customized by editing [proxy.conf](https://github.com/DanielDent/docker-nginx-ssl-proxy/blob/master/proxy.conf) and placing a new copy of it at `/etc/nginx/conf.d/default.conf`.

Example `Dockerfile`:

    FROM danieldent/nginx-ssl-proxy
    COPY proxy.conf /etc/nginx/conf.d/default.conf

## SSL Settings

Reasonable defaults have been chosen for SSL cipher suites using [Mozilla's Recommendations](https://wiki.mozilla.org/Security/Server_Side_TLS). Very old browsers (such as IE6) will be unable to connect with the default settings.

## Security Headers

Reasonable defaults have been chosen with an eye towards a configuration which is more secure by default. See https://www.owasp.org/index.php/List_of_useful_HTTP_headers for more information on the headers used.

## Dependencies

   * [nginx](https://hub.docker.com/_/nginx/) - proxy server
   * [certbot](https://certbot.eff.org/) - for handling certificate creation & validation (+ some wrappers in this image)
   * [envplate](https://github.com/kreuzwerker/envplate) - for allowing use of environment variables in Nginx configuration
   * [s6-overlay](https://github.com/just-containers/s6-overlay) - for PID 1, process supervision, zombie reaping

# Issues, Contributing

If you run into any problems with this image, please check for issues on [GitHub](https://github.com/DanielDent/docker-nginx-ssl-proxy/issues).
Please file a pull request or create a new issue for problems or potential improvements.

# License

Copyright 2015 [Daniel Dent](https://www.danieldent.com/).

Licensed under the Apache License, Version 2.0 (the "License");
you may not use these files except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

Third-party contents included in builds of the image are licensed separately.
