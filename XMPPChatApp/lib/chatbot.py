from chatterbot import ChatBot
import logging
import sys


'''
    This is an example showing how to train a chat bot using the
    ChatterBot Corpus of conversation dialog.
    '''

# Enable info level logging
logging.basicConfig(level=logging.INFO)

chatbot = ChatBot(
                  'Example Bot',
                  trainer='chatterbot.trainers.ChatterBotCorpusTrainer'
                  )

# Start by training our bot with the ChatterBot corpus data
chatbot.train(
              'chatterbot.corpus.english'
              )

# Now let's get a response to a greeting
#response = chatbot.get_response('How are you doing today?')
response = chatbot.get_response(sys.argv[1])

print(response)
