# ACDesktop

With this program I wanted to experiment with random note player using collisions to play a note.

To spice it up there are rotating keyboards and a clef being positioned by a mouse down.

The clef is launched when releasing the mouse button.

![Screenshot](screenshot.png)

# Download the code

Click [here](https://github.com/clemens-tolboom/ACDesktop/archive/master.zip) to download.

# Code snippets

## Physics

I want to rotate the notes so we need some friction.
The animation must go on as long as possible the the collisions must be elastic.

```java
  physics.setFriction(0.01);
  physics.setRestitution(1.0);
```

## Rotating keyboard.

To make a rotating keyboard we need to elements. On that is not moving and one
that does but is attached to the first.

![Rotator](rotator.png)

```java
Body createRotator(float x, float y, float width, float height)
{
  float density = physics.getDensity();

  physics.setDensity(0.0f);
  Body rectFix = physics.createRect( x - 5, y - 5, x + 5, y + 5);

  physics.setDensity(density);
  Body rect = physics.createRect( x - width / 2, y - height / 2, x + width / 2 , y + height / 2);

  physics.createRevoluteJoint(rectFix, rect, x, y);

  return rect;
}
```

## Throwing the clef

As we are in a physics world we must stop the clef from moving (remove it's impulse)
when dragging. To launch it we have to calculate the vector in the physics world
for previous mouse and current mouse.

```java
void mouseDragged()
{
  dragging = true;
  kicker.setLinearVelocity(new Vec2(0,0));
  kicker.setPosition(physics.screenToWorld(new Vec2(mouseX, mouseY)));
}

void mouseReleased()
{
  if (dragging) {
    dragging = false;
    Vec2 mouse = physics.screenToWorld( new Vec2(mouseX, mouseY));
    Vec2 pmouse = physics.screenToWorld( new Vec2(pmouseX, pmouseY));
    Vec2 impulse = mouse.sub(pmouse);
    impulse = impulse.mul(500);
    kicker.applyImpulse(impulse, kicker.getWorldCenter());
  }
}
```
