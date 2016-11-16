package pl.czak.handbuilt;

import android.support.v4.app.FragmentActivity;

import android.os.Bundle;
import android.widget.ImageView;

import com.squareup.picasso.Picasso;

public class MainActivity extends FragmentActivity
{
    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        ImageView imageView = (ImageView) findViewById(R.id.image);
        Picasso.with(this).load("http://i.imgur.com/DvpvklR.png").into(imageView);
    }
}
