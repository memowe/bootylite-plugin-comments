Bootylite::Plugin::Comments - plain file based comments for [Bootylite][b]
==========================================================================

[b]: http://github.com/memowe/Bootylite

This is a simple comments plugin for the Bootylite blog engine. To set it
up, all you need to do is adding some config options and updating your
templates.

CONFIGURATION
-------------

In your `bootylite.conf`:

    plugins => {
        comments => {
            comments_dir => app->home->rel_dir('comments'),
        },
    },

Additional options for this plugin:

* **encoding** - the character encoding for the comment files.
    Default is `utf-8`
* **render_cb** - a callback function which transforms comments to HTML.
    Default is this:

        sub _default_render {
            my $str = shift;

            # no html allowed
            $str = b($str)->html_escape;

            # line break cleanup
            $str =~ s/^\n+//;
            $str =~ s/\n*$/\n\n/;
            $str =~ s/\n\n+/\n\n/;

            # double line breaks: <p></p>
            $str =~ s|(.*?)\n\n|<p>$1</p>|sg;

            # single line breaks: <br>
            $str =~ s/\n/<br>\n/g;

            # prettify
            $str =~ s|</p>|</p>\n\n|g;

            return $str;
        }
* **submit_bridge** - a bridge route that checks submitted comment data for
    validity. Default is none which is bad. Maybe you want to do something
    like this:

        submit_bridge => app->routes->bridge->to(cb => sub {
            my $c = shift;

            # article exists?
            my $url     = $c->param('article_url');
            my $article = $c->booty->get_article($url);
            $c->render_not_found and return unless $article;

            # got name and text?
            my $name    = $c->param('name');
            my $comment = $c->param('comment');
            unless ($name and $comment) {
                $c->res->code(401);
                $c->render_text("Please provide a name and a comment.");
                return;
            }

            # posting too fast?
            my $ip      = $c->tx->remote_address;
            my @comms   = @{$article->all_comments};
            my $last    = (grep {$_->meta->{ip} eq $ip} @comms)[-1];
            if ($last and time - $last->time < 60*5) {
                $c->res->code(401);
                $c->render_text("You're posting too fast.");
                return;
            }

            # everything is fine
            return 1;
        }),
* **moderated** - if true, new comments will be flagged with a `HIDDEN` meta
    key. You need to remove it to let the comment appear in the blog.
    Default is `1`.

OBJECTS
-------

The comments are now available from `Bootylite::Article` objects with the
following methods, but in most cases you need them only in the templates:

* **comment_count** - the number of comments for this article
* **comments** - an arrayref of `Bootylite::Plugin::Comments::Comment`
    objects. These objects have the following goodies for you:
    - **filename** - the absolute path of the corresponding file
    - **time** - the time this comment was created as a unix timestamp
    - **meta** - a hashref of meta information: `name`, `mail`, and `ip`
    - **html** - this comment as html (remember `render_cb`?)

    There's more. Feel free to read the code.

TEMPLATES
---------

The following templates need updates:

* **article.html.ep** - display comments
    and a submit form

        %#---------------------------------------------------------
        <h2>Comments</h2>
        <div id="comments">
        % if (flash 'comment_saved') {
            <p id="message">Thanks! Comment saved!</p>
        % }
        % foreach my $comment (@{$article->comments}) {
            <div class="comment">
                <p class="name"><%= $comment->meta->{name} %></p>
                <%== $comment->html %>
            </div>
        % }
        </div>
        %#---------------------------------------------------------
        <%= form_for post_comment => (method => 'post') => begin %>
            <p>Add your comment:</p>
            <p>Name: <%= input_tag 'name' %></p>
            <p>Mail: <%= input_tag 'mail' %> (used for Gravatar pics only)</p>
            <%= text_area comment => cols => 60 => rows => 5 %>
            <p><%= submit_button 'Submit comment' %></p>
            <%= hidden_field article_url => $article->url %>
        <% end %>
        %#---------------------------------------------------------
    It's up to you to change it but think of the following:

    - the name of the form fields can't be changed.
    - it's good to have an element with the `comments` id.
    - make sure to add the `article_url` as a hidden field.
    - feel free to change the `comment_saved` message.

* **list_articles_short.html.ep** - this template is used for the archive's
    article lists. You want to add the comment count for each article:

        <span class="comments">
            <a href="<%= url_for 'article', article_url => $article->url %>#comments">
                Comments: <%= $article->comment_count %>
            </a>
        </span>

* **show_article.html.ep** - this template is used on other list pages and
    on the article page itself. You want to add the comment count and it's
    exactly the same code as above.

A FEED
------

There's an Atom feed for you to watch comment activity, esp. if you use
moderated comments: `/comment_feed.xml`. If you see new moderated comments,
`ssh` to your Bootylite machine, make sure there's no pron in the new
comments and simply delete the `HIDDEN` meta line.

COPYRIGHT AND LICENCE
---------------------

Copyright (c) 2011 Mirko Westermeier, mail@memowe.de

See the file `MIT-LICENSE` in this distribution for details.
