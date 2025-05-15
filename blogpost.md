# Yet Another Take on Agent-Assisted Programming

I've been fortunate to work for a company that is "all-in" on using LLM assistance in software engineering. That means Cursor is an important part of my daily workflow. But at the same time, it's a demanding job where we have to ship—and sometimes it feels like there's not enough "free time" to explore, just enough time to exploit what you already know.

# Parental Leave

Enter two months of parental leave/new child bonding time. While this is super important, it's not without downtime—little ones nap a lot! So with some extra time and no work pressure, I decided to go a little more "all-in" on using agentic coding to see what would happen.

# Moonrise Viewing App

One evening, we saw an orange moon rising out of our dining room window. It looked great and made me think: I don't want to miss these moments. And while it's all very well-trodden astronomical math that I don't know, major LLMs were probably trained on it.

I started coding up an app in Cursor that would list dates and times of moonrises given:
- Observation latitude/longitude
- Observation declination (e.g., 0 degrees north to 135 degrees southeast)

Having just witnessed an orange moon, I had a test case too.

Unfortunately, using Cursor did not produce anything usable, even after trying with Sonnet 3.7, Gemini 2.5, and GPT-4. It happily produced code, but when it added the test case for my known observation, it could not get the code to work. Most egregiously, one of the attempts to fix the test case hardcoded the engine to return true if the date was April 7th. After a little over a week and many attempts, I decided this was a time sink. Either the workflows weren't good enough, or I wasn't good enough at using them. My hot take is that my instructions were too high-level.

# Migrating Postcard Webapp

I've been running a janky web app, postcardmailer.us, for about seven years. It's on an old version of Ruby and Rails, and Heroku was deprecating support for the stack I was on. The app is such an old version of Ruby that I even had trouble installing it (Docker was the only way that worked). The app is mostly Rails CRUD and a little bit of glue code for formatting the postcard and sending to the direct mailer API. The migration was made harder by having zero tests for the existing project.

I tried this migration process in a few ways:
1. Upgrade the current app to recent Ruby/Rails
2. Create a new Rails app and port functionality over

The first approach never got close to working, and I spent a lot of time starting the migration from scratch with different prompting strategies. Similarly, being too high-level (e.g., "upgrade this app from Rails 5.x to 8.x") did not work.

The second approach got closer to working: I created a postcardmailer app and put the existing app in postcardmailer273, and alongside created a new Ruby/Rails project in postcardmailer342. I then instructed Cursor to port pieces over from the old app to the new app, e.g., "create a Postcard model like the existing app has." At least the new app booted. But the time spent giving properly scoped agentic prompts and correcting its mistakes got frustrating.

# Don't Do What Hurts: Email-Based Postcard App

Migrating the app ended up being another time sink. So I zoomed out and thought: what do I really want? And that's just to be able to send postcards of photos to kids and other family members. In fact, the web app wasn't a great fit: the flow was fairly optimized, but still had enough friction that I just didn't use it.

Way back in 2008, I had a flip phone with a camera but no easy way to transfer photos off of it. I built an app based on Postfix with some Python hooks such that you could SMS a photo to transfer@pixcede.com, and it would store the photo server-side and give you a link.

I decided that in 2025, that was still a pretty decent flow, if you're not willing to build a native iOS/Android app (I'm not). The idea is that you can view a photo on your phone, share it to your email app, and send it to mom@postcardmailer.us with a description of the photo. There are a few other commands that need to be built (signup, adduser), but everything can be done via email with no web/React dependencies.

As opposed to the other time sinks, this immediately started producing results. On day one, I got a hosted version working for just me that would send cards to just me. 100 commits later, it's "finished," and I plan to use it without further maintenance.

# Why Did It Work?

## Scope
After practicing with the other projects, it became clear that the art of using agentic-based coding tools is getting the scope of work sized appropriately:
- Too broad: "List moonrises" gave the agents too much freedom to do the wrong things, and they did.
- Too narrow: "Port this specific thing from the old app" gave the agents too little freedom: I "knew" what had to be done, and fought with the agent to get it right.
- Just right: "Now add a User model that matches based on the email's 'From' address": I knew the order in which to build things, kept the scope to "ticket" level, and built in that order.

## Tests
In the original app, I spent all available programming time building features and never prioritized tests. Since that time, I've matured to realize that tests save you time in the long run (e.g., when you need to upgrade and ensure you're not breaking anything). And with agentic coding, you can essentially get the tests for free. But more importantly with agentic coding, it's part of the autonomous loop:

"Build the signup command and add tests. Make sure the new tests pass and you haven't broken any existing tests."

It's not 100% perfect, and I still verified everything by hand, but the success rate was much higher with tests.

## Interaction Style
While coding personal projects at home, I often have random amounts of free time: 5 minutes here, 10 there, 10 minutes while ostensibly doing something else… and the agentic workflows worked really well for this. I could type a prompt in 1 minute, let it spin for a few minutes while I loaded the laundry, come back and review the changes.

An important mental shift was to care less about the code "quality," or at least some things we've traditionally considered as code quality. I know the service objects I built could be DRYed up, branches re-arranged to be slightly more optimal, or any number of other small things we hold human-coders to. But if I have a fixed number of agent interactions per hour, with a "laundry delay," is it worth an agent interaction to say "DRY up this file," or is it more worthwhile to move onto the next feature? Especially for personal projects, the answer for me was almost always moving onto the next feature.

I also think it's worth mentioning that without this agentic style of building, I probably would not have built this: I simply didn't have enough time, let alone enough focus/flow time to be productive. So in a very real way, using Cursor with agentic programming allowed me to build something I would not have built before.

Similarly, I think this means we've lowered the bar for personal/small-audience apps. I'm looking forward to the day where a Moonrise prompt will yield a fully working app.