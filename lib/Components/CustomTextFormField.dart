import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Customtextformfield extends StatelessWidget{
  final String hintext;
  final TextEditingController myController;
 final String? Function(String?)? validator;
 final FocusNode? focusNode;
  final FlutterTts flutterTts;
 
 final bool obscuretext;
  const Customtextformfield ({super.key,required this.hintext,required this.myController,required this.validator,required this.obscuretext, this.focusNode,required this.flutterTts, });
  @override
  Widget build(BuildContext context) {

  return  TextFormField(
               validator: (val) {
        final result = validator?.call(val);
        if (result != null) {
          flutterTts.speak(result); 
        }
        return result;
      },
                controller:myController,
                obscureText: obscuretext,
                focusNode: focusNode,
                
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: hintext,
                  border: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
              );
  }

}