currentcode

"use client";

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardFooter } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { HelpCircle, Loader2, MessageSquare, X } from 'lucide-react';
import { Toggle } from '@/components/ui/toggle';
import { AWL } from './awl';
import { SAT } from './sat';
import { Oxford5000 } from './oxford5000';


type VocabWord = {
  synonyms: any;
  antonyms: any;
  origin: string;
  word: string;
  pronunciation: string;
  wordForm: string;
  examples: string[];
  description: string;
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
    const wordsArray = newWords.split('\n').filter(word => word.trim() !== '');
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
          <h2 className="text-xl font-bold">Add New Vocabulary Words</h2>
          <Button variant="ghost" onClick={onClose}>
            <X className="w-6 h-6" />
          </Button>
        </div>
        <Textarea
          value={newWords}
          onChange={(e) => setNewWords(e.target.value)}
          placeholder="Example:&#10;Serendipity, Eloquent, Ubiquitous"
          rows={5}
        />
        <div className="flex justify-end mt-4">
          <Button className="bg-black text-white" onClick={handleAddWords} disabled={isLoading}>
            {isLoading ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : 'Add Words'}
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
  const [showWordListButtons, setShowWordListButtons] = useState(false);
  const [selectedWordList, setSelectedWordList] = useState<string[]>([]);
  const [showInstructions, setShowInstructions] = useState(false);
  const [showAddWords, setShowAddWords] = useState(false);
  

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

    setShowingDescription(true);
    setMessages(messages => [
      ...messages,
      { text: `Word Description: ${currentWord.word} (${currentWord.pronunciation}) Word form: ${currentWord.wordForm}.`, sender: 'game' },
      { text: `Examples:${currentWord.examples.map(ex => `\n• ${ex}`).join('')}`, sender: 'game' },
      { text: `${currentWord.description}`, sender: 'game' },
    ]);
    setTimeout(nextWord, 10000);  // Move to next word after 10 seconds
  };

  const getClue = async () => {
    if (!currentWord) return;

    let clueMessage = '';
    switch (guessCount) {
      case 0:
        clueMessage = `This word has ${currentWord.word.length} letters. It starts with ${currentWord.word[0].toUpperCase()} and ends with ${currentWord.word[currentWord.word.length - 1].toUpperCase()}.`;
        break;
      case 1:
        clueMessage = `Part of speech: ${currentWord.wordForm}`;
        break;
      case 2:
        clueMessage = `Pronunciation: ${currentWord.pronunciation}`;
        break;
      case 3:
        clueMessage = `Synonyms: ${currentWord.synonyms}. Antonyms: ${currentWord.antonyms}.`;
        break;
      case 4:
        clueMessage = `Definition: ${currentWord.description}`;
        break;
      case 5:
        clueMessage = `Origin: ${currentWord.origin}.`;
        break;
    }

    setMessages([...messages, { text: clueMessage, sender: 'game' }]);
    setGuessCount(guessCount + 1);
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
  // Existing useState for selectedWordList and showWordListButtons remain
const [awlSelected, setAwlSelected] = useState(false);
const [satSelected, setSatSelected] = useState(false);
const [oxfordSelected, setOxfordSelected] = useState(false);

const handleWordListToggle = (list: React.SetStateAction<string[]>, setter: { (value: React.SetStateAction<boolean>): void; (value: React.SetStateAction<boolean>): void; (value: React.SetStateAction<boolean>): void; (arg0: (prev: any) => boolean): void; }) => {
  setter((prev: any) => {
    const newStatus = !prev;
    setSelectedWordList(newStatus ? list : []);
    return newStatus;
  });
};

  return (
    <Card className="w-96 mx-auto mt-10">
      <CardHeader className="text-2xl font-bold text-center">
        Vocab Drills
      </CardHeader>
      <CardContent>
        <div className="mb-4 text-center space-y-2">
          <div className="flex justify-center space-x-2 mb-2">
            <Toggle
              pressed={isRandomMode}
              onPressedChange={setIsRandomMode}
              aria-label="Toggle random mode"
              className="data-[state=on]:bg-yellow-300 data-[state=on]:text-black"
            >
              {isRandomMode ? "Random Mode (On)" : "Random Mode (Off)"}
            </Toggle>
            <Toggle
              pressed={showInstructions}
              onPressedChange={setShowInstructions}
              aria-label="Toggle instructions"
              className="data-[state=on]:bg-black data-[state=on]:text-white"
            >
              {showInstructions ? "Hide Instructions" : "Show Instructions"}
            </Toggle>
          </div>
          {showInstructions && (
            <div className="text-left bg-gray-200 p-2 rounded mb-2">
              <p>
                <strong>Hướng dẫn chơi:</strong>
              </p>
              <p>
                • Chế độ "Enter Your Words": Người chơi sẽ nhập một số từ vào
                một hộp và trò chơi sẽ bắt đầu.
              </p>
              <p>
                • Chế độ Ngẫu nhiên: Chọn ngẫu nhiên từ vựng từ một nhóm kết hợp
                của danh sách từ AWL (Danh sách 570 từ học thuật), danh sách 500
                từ SAT thông dụng và danh sách 5000 từ Oxford.
              </p>
              <p>
                • Chế độ danh sách từ: Cho phép người chơi chọn xem họ muốn
                luyện tập từ vựng từ AWL, SAT, và Oxford 5000.
              </p>
            </div>
          )}
          {!isRandomMode && (
            <>
              <div className="flex justify-center space-x-2 mb-2">
                <Button
                  className="bg-black text-white"
                  onClick={() => {
                    setShowAddWords(true);
                  }}
                >
                  Enter Your Words
                </Button>
                <Button
                  className="bg-black text-white"
                  onClick={() => setShowWordListButtons(!showWordListButtons)}
                >
                  Word List
                </Button>
              </div>
              {showWordListButtons && (
                <div className="flex justify-center space-x-2 mt-2">
                  <Toggle
                    pressed={awlSelected}
                    onPressedChange={() =>
                      handleWordListToggle(AWL, setAwlSelected)
                    }
                    aria-label="Toggle AWL list"
                    className="data-[state=on]:bg-yellow-300 data-[state=on]:text-black"
                  >
                    AWL
                  </Toggle>
                  <Toggle
                    pressed={satSelected}
                    onPressedChange={() =>
                      handleWordListToggle(SAT, setSatSelected)
                    }
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
            </>
          )}
        </div>
        {showAddWords && (
          <AddWordsDialog
            onAddWords={handleAddWords}
            onClose={() => setShowAddWords(false)}
          />
        )}
        <div className="mb-4 text-center">
          Score: {score} / {round}
        </div>
        <div className="h-72 overflow-y-auto mb-4">
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
        
          <>
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
                <MessageSquare className="w-4 h-4 mr-2" />
                Send
              </Button>
            </div>
            <Button
              className="bg-[#DC2323] text-white w-full"
              onClick={getClue}
            >
              <HelpCircle className="w-4 h-4 mr-2" />
              Get a Clue
            </Button>
          </>
    
      </CardFooter>
    </Card>
  );
};

export default VocabGame;

// At the bottom of your file, outside any React component
const fetchWordDetails = async (word: string): Promise<VocabWord> => {
  const response = await fetch(`https://api.dictionaryapi.dev/api/v2/entries/en/${word}`);
  const data = await response.json();
  
    if (!data.length) { // Checking if the data array is empty
      return {
        word: word,
        pronunciation: '',
        wordForm: '',
        synonyms: [],
        antonyms: [],
        examples: [],
        description: 'No definition found.',
        origin: ''
      };
    }
  
    const details = data[0];
    const meaning = details.meanings[0];
    const definition = meaning.definitions[0];
  
    return {
      word: word,
      pronunciation: details.phonetic || '',
      wordForm: meaning.partOfSpeech || '',
      synonyms: definition.synonyms || [], // Handle potentially undefined synonyms
      antonyms: definition.antonyms || [], // Handle potentially undefined antonyms
      examples: definition.example ? [definition.example] : [],
      description: definition.definition || '',
      origin: details.origin || ''
    };
  };
  


  13:16 mon 15 jul 24
  "use client";

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardFooter } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { FaRandom, FaQuestionCircle, FaPaperPlane, FaLightbulb, FaTimes, FaSpinner } from 'react-icons/fa';
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
          <h2 className="text-xl font-bold">Add New Vocabulary Words</h2>
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
          <Button className="bg-black text-white" onClick={handleAddWords} disabled={isLoading}>
            {isLoading ? <FaSpinner className="w-4 h-4 mr-2 animate-spin" /> : 'Add Words'}
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

    // Append word form if available
    if (currentWord.wordForm.trim()) {
      messageContent.push(`Word form: ${currentWord.wordForm}`);
    }

    // Append description if available
    const description = currentWord.description.trim()
      ? currentWord.description
      : "No description available.";
    messageContent.push(`Description: ${description}`);

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
    if (currentWord.word.length) {
      clues.push(`This word has ${currentWord.word.length} letters. It starts with ${currentWord.word[0].toUpperCase()} and ends with ${currentWord.word[currentWord.word.length - 1].toUpperCase()}.`);
    }
    if (currentWord.wordForm) {
      clues.push(`Part of speech: ${currentWord.wordForm}`);
    }
    if (currentWord.pronunciation) {
      clues.push(`Pronunciation: ${currentWord.pronunciation}`);
    }
    if (currentWord.synonyms.length || currentWord.antonyms.length) {
      clues.push(`Synonyms: ${currentWord.synonyms.join(', ')}. Antonyms: ${currentWord.antonyms.join(', ')}.`);
    }
    if (currentWord.description) {
      clues.push(`Definition: ${currentWord.description}`);
    }
    if (currentWord.origin) {
      clues.push(`Origin: ${currentWord.origin}`);
    }

    if (clues.length > guessCount) {
      setMessages([...messages, { text: clues[guessCount], sender: 'game' }]);
      setGuessCount(guessCount + 1);
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
    currentWord.wordForm ? 1 : 0,
    currentWord.pronunciation ? 1 : 0,
    currentWord.synonyms.length || currentWord.antonyms.length ? 1 : 0,
    currentWord.description ? 1 : 0,
    currentWord.origin ? 1 : 0
  ].reduce((a, b) => a + b, 0) : 0;

  return (
    <Card className="w-96 mx-auto mt-10">
      <Toaster />
      <CardHeader className="text-2xl font-bold text-center">
        Vocab Drills
      </CardHeader>
      <CardContent>
        <div className="mb-4 text-center space-y-2">
          <div className="flex justify-center space-x-2 mb-2">
            <Toggle
              pressed={isRandomMode}
              onPressedChange={() => {
                setIsRandomMode((prev) => !prev); // This will toggle the state based on its previous value
                setIsEnterWordsMode(false); // Ensure other modes are turned off when this is turned on
                setShowWordListButtons(false); // Hide word list buttons when random mode is toggled
                setAwlSelected(false);
                setSatSelected(false);
                setOxfordSelected(false);
                if (!isRandomMode) {
                  // If turning on random mode, set up the combined words list
                  const combinedWords = [...AWL, ...SAT, ...Oxford5000];
                  setSelectedWordList(combinedWords);
                } else {
                  setSelectedWordList([]); // Clear the word list if random mode is turned off
                }
              }}
              aria-label="Toggle random mode"
              className="data-[state=on]:bg-yellow-300 data-[state=on]:text-black"
            >
              <FaRandom className="w-6 h-6" />
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
          {showInstructions && (
            <div className="text-left bg-gray-200 p-2 rounded mb-2">
              <p>
                <strong>Hướng dẫn chơi:</strong>
              </p>
              <p>
                • Chế độ Ngẫu nhiên (mặc định): Chọn ngẫu nhiên từ danh sách AWL
                (Danh sách 570 từ học thuật), danh sách 500 từ SAT thông dụng và
                danh sách 5000 từ Oxford.
              </p>
              <p>
                • Chế độ "Enter Your Words": Người chơi sẽ nhập một số từ vào
                một hộp và trò chơi sẽ bắt đầu.
              </p>
              <p>
                • Chế độ danh sách từ: Cho phép người chơi chọn xem họ muốn
                luyện tập từ vựng từ AWL, SAT, và Oxford 5000.
              </p>
            </div>
          )}
          {!isRandomMode && !isEnterWordsMode && (
            <>
              <div className="flex justify-center space-x-2 mb-2">
                <Button
                  className="bg-black text-white"
                  onClick={() => {
                    setIsEnterWordsMode(true);
                    setIsRandomMode(false);
                    setShowWordListButtons(false);
                    setAwlSelected(false);
                    setSatSelected(false);
                    setOxfordSelected(false);
                    setShowAddWords(true);
                  }}
                >
                  Enter Your Words
                </Button>
                <Button
                  className="bg-black text-white"
                  onClick={() => {
                    setShowWordListButtons(!showWordListButtons);
                    setIsEnterWordsMode(false);
                  }}
                >
                  Word List
                </Button>
              </div>
              {showWordListButtons && (
                <div className="flex justify-center space-x-2 mt-2">
                  <Toggle
                    pressed={awlSelected}
                    onPressedChange={() =>
                      handleWordListToggle(AWL, setAwlSelected)
                    }
                    aria-label="Toggle AWL list"
                    className="data-[state=on]:bg-yellow-300 data-[state=on]:text-black"
                  >
                    AWL
                  </Toggle>
                  <Toggle
                    pressed={satSelected}
                    onPressedChange={() =>
                      handleWordListToggle(SAT, setSatSelected)
                    }
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
            </>
          )}
        </div>
        {showAddWords && (
          <AddWordsDialog
            onAddWords={handleAddWords}
            onClose={() => setShowAddWords(false)}
          />
        )}
        <div className="mb-4 text-center">
          Score: {score} / {round}
        </div>
        <div className="h-72 overflow-y-auto mb-4">
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
  try {
    const response = await fetch(`https://api.dictionaryapi.dev/api/v2/entries/en/${word}`);
    const data = await response.json();

    if (!data.length) {
      return {
        word: word,
        pronunciation: '',
        wordForm: '',
        synonyms: [],
        antonyms: [],
        examples: [],
        description: 'No description available.',
        origin: ''
      };
    }

    const details = data[0];
    const meaning = details.meanings[0];
    const definition = meaning.definitions[0];

    return {
      word: word,
      pronunciation: details.phonetic || '',
      wordForm: meaning.partOfSpeech || '',
      synonyms: definition.synonyms || [],
      antonyms: definition.antonyms || [],
      examples: definition.example ? [definition.example] : [],
      description: definition.definition || '',
      origin: details.origin || ''
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
      origin: ''
    };
  }
};

14:52 mon 15 july 24

"use client";

import React, { useState, useEffect } from 'react';
import { Card, CardContent, CardHeader, CardFooter } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Textarea } from '@/components/ui/textarea';
import { FaRandom, FaQuestionCircle, FaPaperPlane, FaLightbulb, FaTimes, FaSpinner } from 'react-icons/fa';
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
          <h2 className="text-xl font-bold">Add New Vocabulary Words</h2>
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

    // Append word form if available
    if (currentWord.wordForm.trim()) {
      messageContent.push(`Word form: ${currentWord.wordForm}`);
    }

    // Append description if available
    const description = currentWord.description.trim()
      ? currentWord.description
      : "No description available.";
    messageContent.push(`Description: ${description}`);

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
    if (currentWord.word.length) {
      clues.push(`This word has ${currentWord.word.length} letters. It starts with ${currentWord.word[0].toUpperCase()} and ends with ${currentWord.word[currentWord.word.length - 1].toUpperCase()}.`);
    }
    if (currentWord.wordForm) {
      clues.push(`Part of speech: ${currentWord.wordForm}`);
    }
    if (currentWord.pronunciation) {
      clues.push(`Pronunciation: ${currentWord.pronunciation}`);
    }
    if (currentWord.synonyms.length || currentWord.antonyms.length) {
      clues.push(`Synonyms: ${currentWord.synonyms.join(', ')}. Antonyms: ${currentWord.antonyms.join(', ')}.`);
    }
    if (currentWord.description) {
      clues.push(`Definition: ${currentWord.description}`);
    }
    if (currentWord.origin) {
      clues.push(`Origin: ${currentWord.origin}`);
    }

    if (clues.length > guessCount) {
      setMessages([...messages, { text: clues[guessCount], sender: 'game' }]);
      setGuessCount(guessCount + 1);
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
    currentWord.wordForm ? 1 : 0,
    currentWord.pronunciation ? 1 : 0,
    currentWord.synonyms.length || currentWord.antonyms.length ? 1 : 0,
    currentWord.description ? 1 : 0,
    currentWord.origin ? 1 : 0
  ].reduce((a, b) => a + b, 0) : 0;

  return (
    <Card className="w-96 mx-auto mt-10">
      <Toaster />
      <CardHeader className="text-2xl font-bold text-center">
        Vocab Drills
      </CardHeader>
      <CardContent>
        <div className="mb-4 text-center space-y-2">
          <div className="flex justify-center space-x-2 mb-2">
            <Toggle
              pressed={isRandomMode}
              onPressedChange={() => {
                setIsRandomMode((prev) => !prev); // This will toggle the state based on its previous value
                setIsEnterWordsMode(false); // Ensure other modes are turned off when this is turned on
                setShowWordListButtons(false); // Hide word list buttons when random mode is toggled
                setAwlSelected(false);
                setSatSelected(false);
                setOxfordSelected(false);
                if (!isRandomMode) {
                  // If turning on random mode, set up the combined words list
                  const combinedWords = [...AWL, ...SAT, ...Oxford5000];
                  setSelectedWordList(combinedWords);
                } else {
                  setSelectedWordList([]); // Clear the word list if random mode is turned off
                }
              }}
              aria-label="Toggle random mode"
              className="data-[state=on]:bg-yellow-300 data-[state=on]:text-black"
            >
              <FaRandom className="w-6 h-6" />
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
          {showInstructions && (
            <div className="text-left bg-gray-200 p-2 rounded mb-2">
              <p>
                <strong>Hướng dẫn chơi:</strong>
              </p>
              <p>
                • Chế độ Ngẫu nhiên (mặc định): Chọn ngẫu nhiên từ danh sách AWL
                (Danh sách 570 từ học thuật), danh sách 500 từ SAT thông dụng và
                danh sách 5000 từ Oxford.
              </p>
              <p>
                • Chế độ "Enter Your Words": Người chơi sẽ nhập một số từ vào
                một hộp và trò chơi sẽ bắt đầu.
              </p>
              <p>
                • Chế độ danh sách từ: Cho phép người chơi chọn xem họ muốn
                luyện tập từ vựng từ AWL, SAT, và Oxford 5000.
              </p>
            </div>
          )}
          {!isRandomMode && !isEnterWordsMode && (
            <>
              <div className="flex justify-center space-x-2 mb-2">
                <Button
                  className="bg-black text-white"
                  onClick={() => {
                    setIsEnterWordsMode(true);
                    setIsRandomMode(false);
                    setShowWordListButtons(false);
                    setAwlSelected(false);
                    setSatSelected(false);
                    setOxfordSelected(false);
                    setShowAddWords(true);
                  }}
                >
                  Enter Your Words
                </Button>
                <Button
                  className="bg-black text-white"
                  onClick={() => {
                    setShowWordListButtons(!showWordListButtons);
                    setIsEnterWordsMode(false);
                  }}
                >
                  Word List
                </Button>
              </div>
              {showWordListButtons && (
                <div className="flex justify-center space-x-2 mt-2">
                  <Toggle
                    pressed={awlSelected}
                    onPressedChange={() =>
                      handleWordListToggle(AWL, setAwlSelected)
                    }
                    aria-label="Toggle AWL list"
                    className="data-[state=on]:bg-yellow-300 data-[state=on]:text-black"
                  >
                    AWL
                  </Toggle>
                  <Toggle
                    pressed={satSelected}
                    onPressedChange={() =>
                      handleWordListToggle(SAT, setSatSelected)
                    }
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
            </>
          )}
        </div>
        {showAddWords && (
          <AddWordsDialog
            onAddWords={handleAddWords}
            onClose={() => setShowAddWords(false)}
          />
        )}
        <div className="mb-4 text-center">
          Score: {score} / {round}
        </div>
        <div className="h-72 overflow-y-auto mb-4">
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
  try {
    const response = await fetch(`https://api.dictionaryapi.dev/api/v2/entries/en/${word}`);
    const data = await response.json();

    if (!data.length) {
      return {
        word: word,
        pronunciation: '',
        wordForm: '',
        synonyms: [],
        antonyms: [],
        examples: [],
        description: 'No description available.',
        origin: ''
      };
    }

    const details = data[0];
    const meaning = details.meanings[0];
    const definition = meaning.definitions[0];

    return {
      word: word,
      pronunciation: details.phonetic || '',
      wordForm: meaning.partOfSpeech || '',
      synonyms: definition.synonyms || [],
      antonyms: definition.antonyms || [],
      examples: definition.example ? [definition.example] : [],
      description: definition.definition || '',
      origin: details.origin || ''
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
      origin: ''
    };
  }
};
