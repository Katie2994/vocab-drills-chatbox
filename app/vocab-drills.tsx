"use client";

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardFooter } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { FaRandom, FaQuestionCircle, FaPaperPlane, FaLightbulb, FaTimes, FaBookOpen, FaPlus } from 'react-icons/fa';
import toast, { Toaster } from 'react-hot-toast';
import { Toggle } from '@/components/ui/toggle';
import { AWL } from './awl';
import { SAT } from './sat';
import { Oxford5000 } from './oxford5000';

type VocabWord = {
  synonyms: string[];
  antonyms: string[];
  origin: string;
  word: string;
  pronunciation: string;
  wordForm: string;
  examples: string[];
  description: string;
  syllables: number;
  derivation: string;
};


type Message = {
  text: string;
  sender: string;
};

type AddWordsProps = {
  onAddWords: (words: VocabWord[]) => void;
  onClose: () => void;
};

const AddWordsDialog: React.FC<AddWordsProps> = ({ onAddWords, onClose }) => {
  const [newWords, setNewWords] = useState<string>('');
  const [isLoading, setIsLoading] = useState<boolean>(false);

  const handleAddWords = async () => {
    setIsLoading(true);
    const wordsArray = newWords.split(',').map(word => word.trim()).filter(word => word !== '');
    const newWordObjects = await Promise.all(wordsArray.map(fetchWordDetails));
    onAddWords(newWordObjects);
    setNewWords('');
    setIsLoading(false);
    onClose();
  };
  
  return (
    <div className="fixed inset-0 flex items-center justify-center bg-black bg-opacity-50 z-50">
      <div className="bg-white p-4 rounded-lg max-w-md w-full">
        <div className="flex justify-between items-center mb-4">
          <h2 className="text-xl font-bold">Enter New Words</h2>
          <Button variant="ghost" onClick={onClose}>
            <FaTimes className="w-6 h-6" />
          </Button>
        </div>
        <Textarea
          value={newWords}
          onChange={(e) => setNewWords(e.target.value)}
          placeholder="Example:&#10;Serendipity, Eloquent, Ubiquitous"
          rows={5}
        />
        <div className="flex justify-end mt-4">
          <Button
            className="bg-black text-white"
            onClick={handleAddWords}
            disabled={isLoading}
          >
            {isLoading ? (
              <div className="w-4 h-4 mr-0 border-2 border-t-transparent border-white rounded-full animate-spin"></div>
            ) : (
              "Add Words"
            )}
          </Button>
        </div>
      </div>
    </div>
  );
};

const VocabGame = () => {
  const [currentWord, setCurrentWord] = useState<VocabWord | null>(null);
  const [userInput, setUserInput] = useState('');
  const [messages, setMessages] = useState<Message[]>([]);
  const [score, setScore] = useState(0);
  const [round, setRound] = useState(0);
  const [guessCount, setGuessCount] = useState(0);
  const [showingDescription, setShowingDescription] = useState(false);
  const [isRandomMode, setIsRandomMode] = useState(true);
  const [isEnterWordsMode, setIsEnterWordsMode] = useState(false);
  const [showWordListButtons, setShowWordListButtons] = useState(false);
  const [selectedWordList, setSelectedWordList] = useState<string[]>([]);
  const [showInstructions, setShowInstructions] = useState(false);
  const [showAddWords, setShowAddWords] = useState(false);
  const [awlSelected, setAwlSelected] = useState(false);
  const [satSelected, setSatSelected] = useState(false);
  const [oxfordSelected, setOxfordSelected] = useState(false);
  

  useEffect(() => {
    if (isRandomMode) {
      const combinedWords = [...AWL, ...SAT, ...Oxford5000];
      setSelectedWordList(combinedWords);
    }
  }, [isRandomMode]);

  useEffect(() => {
    if (selectedWordList.length > 0) {
      nextWord();
    }
  }, [selectedWordList]);

  const nextWord = async () => {
    if (selectedWordList.length === 0) return;
    const randomIndex = Math.floor(Math.random() * selectedWordList.length);
    const selectedWord = selectedWordList[randomIndex];
    const wordDetails = await fetchWordDetails(selectedWord);
    setCurrentWord(wordDetails);
    setUserInput('');
    setRound(round + 1);
    setGuessCount(0);
    setShowingDescription(false);
    toast.success('New word arrived!', {
      icon: '🔔',
      style: {
        borderRadius: '10px',
        background: '#333',
        color: '#fff',
      },
    });
  };

  const checkAnswer = () => {
    if (userInput.trim() === '' || !currentWord) return;

    const isCorrect = userInput.toLowerCase() === currentWord.word.toLowerCase();
    if (isCorrect) {
      setMessages([
        ...messages,
        { text: userInput, sender: 'user' },
        { text: "That's correct! Well done!", sender: 'game' }
      ]);
      setScore(score + 1);
      showWordDescription();
      toast.success('You guessed it right!', {
        icon: '🎉',
        position:'bottom-center',
        style: {
          borderRadius: '10px',
          background: '#333',
          color: '#fff',
        },
      });
    } else {
      setGuessCount(guessCount + 1);
      if (guessCount >= 2) {
        setMessages([
          ...messages,
          { text: userInput, sender: 'user' },
          { text: `Sorry, that's not correct. The word is: ${currentWord.word}`, sender: 'game' }
        ]);
        showWordDescription();
      } else {
        setMessages([
          ...messages,
          { text: userInput, sender: 'user' },
          { text: "That's not quite right. Try again!", sender: 'game' }
        ]);
      }
    }
    setUserInput('');
  };

  const showWordDescription = () => {
    if (!currentWord) return;

    // Set up initial message with basic details
    let messageContent = [`Word: ${currentWord.word}`];

    // Append pronunciation if available
    if (currentWord.pronunciation.trim()) {
      messageContent.push(`Pronunciation: ${currentWord.pronunciation}`);
    }

    // Append examples if available
    if (currentWord.examples.length > 0) {
      const examplesContent = currentWord.examples
        .map((example) => `• ${example}`)
        .join("\n");
      messageContent.push(`Examples:\n${examplesContent}`);
    }

    // Append origin if available
    if (currentWord.origin.trim()) {
      messageContent.push(`Origin: ${currentWord.origin}`);
    }

    // Updating the message state with the constructed message content
    setShowingDescription(true);
    setMessages((messages) => [
      ...messages,
      { text: messageContent.join('; '), sender: 'game' } // Ensure proper punctuation at the end
    ]);

    // Move to next word after a delay
    setTimeout(nextWord, 10000);
  };

  const getClue = async () => {
    if (!currentWord) return;

    let clues = [];

    // Add the clue for word length, first and last letters
    if (currentWord.word.length) {
      clues.push(
        `This word has ${
          currentWord.word.length
        } letters. It starts with ${currentWord.word[0].toUpperCase()} and ends with ${currentWord.word[
          currentWord.word.length - 1
        ].toUpperCase()}.`
      );
    }

    // Add the syllable count
    if (currentWord.syllables) {
      clues.push(`It has ${currentWord.syllables} syllables.`);
    }

    // Add the pronunciation
    if (currentWord.pronunciation) {
      clues.push(`Pronunciation: ${currentWord.pronunciation}`);
    }

    // Add the part of speech if available
    if (currentWord.wordForm) {
      clues.push(`Part of speech: ${currentWord.wordForm}`);
    }

    // Add synonyms if available and not empty
    if (currentWord.synonyms.length > 0) {
      clues.push(`Synonyms: ${currentWord.synonyms.join(", ")}.`);
    }

    // Add definitions
    if (currentWord.description) {
      clues.push(`Definitions: ${currentWord.description}`);
    }

    // Add derivation if available and not empty
    if (currentWord.derivation) {
      clues.push(`Derivation: ${currentWord.derivation}`);
    }

    // Add origin if available and not empty
    if (currentWord.origin) {
      clues.push(`Origin: ${currentWord.origin}`);
    }

    // Showing clues based on the number of incorrect guesses
    if (guessCount < clues.length) {
      setMessages([...messages, { text: clues[guessCount], sender: "game" }]);
      setGuessCount(guessCount + 1); // Increment only if a clue is given
    }
  };  

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Enter' || e.key === ' ') {
      e.preventDefault();
      checkAnswer();
    }
  };

  const handleAddWords = (newWords: VocabWord[]) => {
    setSelectedWordList([...selectedWordList, ...newWords.map(word => word.word)]);
  };

  const handleWordListToggle = (list: string[], setter: React.Dispatch<React.SetStateAction<boolean>>) => {
    setter((prev) => {
      const newStatus = !prev;
      setSelectedWordList(newStatus ? list : []);
      setIsRandomMode(false);
      setIsEnterWordsMode(false);
      return newStatus;
    });
  };

  const totalClues = (currentWord) ? [
    currentWord.word.length ? 1 : 0,
    currentWord.syllables ? 1 : 0,
    currentWord.pronunciation ? 1 : 0,
    currentWord.wordForm ? 1 : 0,
    currentWord.synonyms.length ? 1 : 0,
    currentWord.description ? 1 : 0,
    currentWord.derivation ? 1 : 0,
    currentWord.origin ? 1 : 0
  ].reduce((a, b) => a + b, 0) : 0;
  

  return (
    <Card className="w-96 mx-auto mt-10 relative">
      <Toaster></Toaster>
      <CardHeader className="text-2xl font-bold text-center">
        Vocab Drills
      </CardHeader>
      <CardContent className="flex-justify overflow-scroll"></CardContent>
      <CardContent>
        <div className="mb-4 text-center space-y-2">
          <div className="flex justify-center space-x-2 mb-2">
            <Toggle
              pressed={isEnterWordsMode}
              onPressedChange={() => {
                setIsEnterWordsMode((prev) => !prev);
                setIsRandomMode(false);
                setShowWordListButtons(false);
                setShowAddWords(isEnterWordsMode ? false : true); // Only toggle showAddWords if entering words mode was not already active
              }}
              aria-label="Toggle enter words mode"
              className="data-[state=on]:bg-black data-[state=on]:text-white"
            >
              <FaPlus className="w-6 h-6" />
            </Toggle>
            <Toggle
              pressed={isRandomMode}
              onPressedChange={() => {
                setIsRandomMode((prev) => !prev);
                setIsEnterWordsMode(false);
                setShowWordListButtons(false);
                if (!isRandomMode) {
                  const combinedWords = [...AWL, ...SAT, ...Oxford5000];
                  setSelectedWordList(combinedWords);
                } else {
                  setSelectedWordList([]);
                }
              }}
              aria-label="Toggle random mode"
              className="data-[state=on]:bg-yellow-300 data-[state=on]:text-black"
            >
              <FaRandom className="w-6 h-6" />
            </Toggle>
            <Toggle
              pressed={showWordListButtons}
              onPressedChange={() => {
                setShowWordListButtons((prev) => !prev);
                setIsEnterWordsMode(false);
                setIsRandomMode(false);
              }}
              aria-label="Toggle word list"
              className="data-[state=on]:bg-black data-[state=on]:text-white"
            >
              <FaBookOpen className="w-6 h-6" />
            </Toggle>
            <Toggle
              pressed={showInstructions}
              onPressedChange={setShowInstructions}
              aria-label="Toggle instructions"
              className="data-[state=on]:bg-black data-[state=on]:text-white"
            >
              <FaQuestionCircle className="w-6 h-6" />
            </Toggle>
          </div>
        </div>
        {showWordListButtons && (
          <div className="flex justify-center space-x-2 mt-2">
            <Toggle
              pressed={awlSelected}
              onPressedChange={() => handleWordListToggle(AWL, setAwlSelected)}
              aria-label="Toggle AWL list"
              className="data-[state=on]:bg-yellow-300 data-[state=on]:text-black"
            >
              AWL
            </Toggle>
            <Toggle
              pressed={satSelected}
              onPressedChange={() => handleWordListToggle(SAT, setSatSelected)}
              aria-label="Toggle SAT list"
              className="data-[state=on]:bg-yellow-300 data-[state=on]:text-black"
            >
              SAT
            </Toggle>
            <Toggle
              pressed={oxfordSelected}
              onPressedChange={() =>
                handleWordListToggle(Oxford5000, setOxfordSelected)
              }
              aria-label="Toggle Oxford 5000 list"
              className="data-[state=on]:bg-yellow-300 data-[state=on]:text-black"
            >
              Oxford 5000
            </Toggle>
          </div>
        )}
        {showInstructions && (
          <div className="text-left bg-yellow-300 p-2 rounded mb-2">
            <p>
              <strong>Hướng dẫn chơi:</strong>
            </p>
            <p>
              • Chế độ Ngẫu nhiên (mặc định): Chọn ngẫu nhiên từ danh sách AWL,
              danh sách 500 từ SAT thông dụng và danh sách 5000 từ Oxford.
            </p>
            <p>
              • Chế độ "Enter Your Words": Người chơi sẽ nhập một số từ vào một
              hộp và trò chơi sẽ bắt đầu.
            </p>
            <p>
              • Chế độ danh sách từ: Cho phép người chơi chọn xem họ muốn luyện
              tập từ vựng từ AWL, SAT, và Oxford 5000.
            </p>
          </div>
        )}
        {showAddWords && (
          <AddWordsDialog
            onAddWords={handleAddWords}
            onClose={() => setShowAddWords(false)}
          />
        )}
        <div className="mb-4 text-center">
          Score: {score} / {round}
        </div>
        <div className="h-96 overflow-y-scroll mb-4">
          {messages.map((message, index) => (
            <div
              key={index}
              className={`mb-2 ${
                message.sender === "user" ? "text-right" : "text-left"
              }`}
            >
              <span
                className={`inline-block p-2 rounded-lg ${
                  message.sender === "user"
                    ? "bg-black text-white"
                    : "bg-gray-200"
                }`}
              >
                {message.text}
              </span>
            </div>
          ))}
        </div>
      </CardContent>
      <CardFooter className="flex flex-col">
        <div className="flex w-full mb-2">
          <Input
            type="text"
            value={userInput}
            onChange={(e) => setUserInput(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Type your answer"
            className="flex-grow mr-2"
          />
          <Button
            className="bg-yellow-300 text-black flex-shrink-0"
            onClick={checkAnswer}
          >
            <FaPaperPlane className="w-4 h-4 mr-2" />
            Send
          </Button>
        </div>
        <Button className="bg-[#DC2323] text-white w-full" onClick={getClue}>
          <FaLightbulb className="w-4 h-4 mr-2" />
          Get a Clue ({guessCount} / {totalClues})
        </Button>
      </CardFooter>
    </Card>
  );
};

export default VocabGame;

// At the bottom of your file, outside any React component
const fetchWordDetails = async (word: string): Promise<VocabWord> => {
  const url = `https://wordsapiv1.p.rapidapi.com/words/${word}`;
  const options = {
    method: 'GET',
    headers: {
      'x-rapidapi-key': '95b1a8dfc1msh2098de07efd8b44p1475aejsnd26063f62c48', // Replace 'my-api-key' with your actual API key
      'x-rapidapi-host': 'wordsapiv1.p.rapidapi.com'
    }
  };

  try {
    const response = await fetch(url, options);
    const data = await response.json();

    // Debug the API response
    console.log('API response:', data);

    // Aggregate definitions and details
    const definitions = data.results || [];
    const pronunciation = data.pronunciation && typeof data.pronunciation.all === 'string' ? data.pronunciation.all : '';
    
    // Use a Set to store unique parts of speech
    const partOfSpeechSet = new Set();
    definitions.forEach((def: { partOfSpeech: unknown; }) => {
      if (def.partOfSpeech) {
        partOfSpeechSet.add(def.partOfSpeech);
      }
    });
    const wordForm = Array.from(partOfSpeechSet).join(', '); // Convert set back to string

    const synonyms = definitions.flatMap((def: { synonyms: any; }) => def.synonyms || []).slice(0, 3);
    const antonyms = definitions.flatMap((def: { antonyms: any; }) => def.antonyms || []).slice(0, 3);
    const examples = definitions.flatMap((def: { examples: any; }) => def.examples || []).slice(0, 3);
    const description = definitions.map((def: { definition: any; }) => `• ${def.definition}`).join('; ') || 'No description available.';
    const origin = typeof data.origin === 'string' ? data.origin : '';
    const syllables = data.syllables && Array.isArray(data.syllables.list) ? data.syllables.list.length : 0;
    const derivation = data.derivation && Array.isArray(data.derivation) ? data.derivation.join(', ') : '';

    return {
      word: data.word || word,
      pronunciation,
      wordForm,
      synonyms,
      antonyms,
      examples,
      description,
      origin,
      syllables,
      derivation
    };
  } catch (error) {
    console.error('Error fetching word details:', error);
    return {
      word: word,
      pronunciation: '',
      wordForm: '',
      synonyms: [],
      antonyms: [],
      examples: [],
      description: 'Error fetching definition.',
      origin: '',
      syllables: 0,
      derivation: ''
    };
  }
};






