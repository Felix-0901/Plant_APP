import 'package:flutter/material.dart';
import 'sign_in.dart';
import 'signup.dart';
import 'tools.dart';
// import 'main_page.dart';

class Homepage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.network(
            "https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTeX8k7dUKajhJjQ4Iev7hv3HP3NUt3ogYobQ&s",
            fit: BoxFit.cover,
          ),
        ),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipOval(
                child: Image.network(
                  "https://buy-obs.line-scdn.net/0hcxGx3AVaPFd6AS_ayNJDAClVMDcFLydVEz8jLw1aYy8EbgNKLWUQbCB3IyArR35JPTgPOQ9eEmQsbhsJLRUYMT5kFTwEMgRIFAEPNQ1KAScrRAtdFgJydw",
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ), 
              SizedBox(
                height: 50,
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HomepageButtonModel(
                    text: "登入",
                    onTap: (){
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (context) => SignIn()),
                      );
                    }, 
                  ),
                  SizedBox(
                    width: 25,
                  ),
                  HomepageButtonModel(
                    text: "註冊",
                    onTap:(){
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (context) => Signup()),
                      );
                    }, 
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}