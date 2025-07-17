{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE ViewPatterns #-}

import Data.Aeson (Value, (.=), object)
import Network.Wai.Handler.Warp (run)
import System.Environment (lookupEnv)
import Text.Cassius
import Text.Hamlet
import Text.Julius
import Text.Read (readMaybe)
import Yesod
import Yesod.Static

-- Static files
$(staticFiles "static")

-- Foundation type
data App = App
  { getStatic :: Static
  }

-- URL routes
$(mkYesod
    "App"
    [parseRoutes|
/static StaticR Static getStatic
/ HomeR GET
/program ProgramR GET
/api/data DataR GET
|])

-- Make App an instance of Yesod
instance Yesod App
    -- Add security headers for production
                                           where
  yesodMiddleware = defaultYesodMiddleware

-- Route handlers
getHomeR :: Handler Html
getHomeR =
  defaultLayout $ do
    setTitle "Home - My SPA"
    addStylesheetRemote
      "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css"
    toWidget
      [hamlet|
<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
    <div class="container">
        <a class="navbar-brand" href="@{HomeR}">My SPA
        <div class="navbar-nav">
            <a class="nav-link" href="@{HomeR}">Home
            <a class="nav-link" href="@{ProgramR}">Program

<div class="container mt-4">
    <div id="home-content">
        <div class="row">
            <div class="col-md-8">
                <h1>Welcome to My SPA
                <p>This is a single-page application built with Yesod and deployed on Render.
                <p>Navigate between pages using the menu above, or click the buttons below for dynamic content.
                
                <div class="mt-4">
                    <button class="btn btn-primary" onclick="loadHomeData()">Load Home Data
                    <button class="btn btn-secondary ms-2" onclick="loadProgramData()">Load Program Data
                
                <div id="dynamic-content" class="mt-4">
                    <!-- Dynamic content will be loaded here -->
            
            <div class="col-md-4">
                <div class="card">
                    <div class="card-body">
                        <h5 class="card-title">Quick Actions
                        <p class="card-text">Use these buttons to interact with the application:
                        <a href="@{ProgramR}" class="btn btn-outline-primary">Go to Program
                        <button class="btn btn-outline-success" onclick="refreshData()">Refresh Data
|]
    toWidget
      [julius|
function loadHomeData() {
    fetch('@{DataR}?type=home')
        .then(response => response.json())
        .then(data => {
            document.getElementById('dynamic-content').innerHTML = 
                '<div class="alert alert-info"><h4>Home Data</h4><p>' + data.message + '</p></div>';
        })
        .catch(error => {
            console.error('Error:', error);
            document.getElementById('dynamic-content').innerHTML = 
                '<div class="alert alert-danger">Error loading data</div>';
        });
}

function loadProgramData() {
    fetch('@{DataR}?type=program')
        .then(response => response.json())
        .then(data => {
            document.getElementById('dynamic-content').innerHTML = 
                '<div class="alert alert-success"><h4>Program Data</h4><p>' + data.message + '</p></div>';
        });
}

function refreshData() {
    document.getElementById('dynamic-content').innerHTML = 
        '<div class="alert alert-warning">Data refreshed at ' + new Date().toLocaleTimeString() + '</div>';
}
|]
    toWidget
      [cassius|
body
    font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif
    background-color: #f8f9fa

.navbar-brand
    font-weight: bold
    font-size: 1.5rem

.card
    border: none
    border-radius: 10px
    box-shadow: 0 2px 10px rgba(0,0,0,0.1)

.btn
    border-radius: 25px
    font-weight: 500
|]

getProgramR :: Handler Html
getProgramR =
  defaultLayout $ do
    setTitle "Program - My SPA"
    addStylesheetRemote
      "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/css/bootstrap.min.css"
    toWidget
      [hamlet|
<nav class="navbar navbar-expand-lg navbar-dark bg-dark">
    <div class="container">
        <a class="navbar-brand" href="@{HomeR}">My SPA
        <div class="navbar-nav">
            <a class="nav-link" href="@{HomeR}">Home
            <a class="nav-link" href="@{ProgramR}">Program

<div class="container mt-4">
    <div id="program-content">
        <div class="row">
            <div class="col-md-12">
                <h1>Program Page
                <p>This is the program section of your SPA running on Render.
                
                <div class="row mt-4">
                    <div class="col-md-6">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">Program Features
                                <ul class="list-group list-group-flush">
                                    <li class="list-group-item">Feature 1: Dynamic content loading
                                    <li class="list-group-item">Feature 2: Real-time updates
                                    <li class="list-group-item">Feature 3: Interactive components
                                <button class="btn btn-primary mt-3" onclick="loadProgramInfo()">Load Program Info
                    
                    <div class="col-md-6">
                        <div class="card">
                            <div class="card-body">
                                <h5 class="card-title">Program Stats
                                <div id="program-stats">
                                    <div class="d-flex justify-content-between">
                                        <span>Active Users:
                                        <span id="active-users">--
                                    <div class="d-flex justify-content-between">
                                        <span>Total Programs:
                                        <span id="total-programs">--
                                    <div class="d-flex justify-content-between">
                                        <span>Success Rate:
                                        <span id="success-rate">--
                                <button class="btn btn-success mt-3" onclick="updateStats()">Update Stats
                
                <div id="program-dynamic-content" class="mt-4">
                    <!-- Dynamic program content -->
|]
    addScriptRemote
      "https://cdn.jsdelivr.net/npm/bootstrap@5.1.3/dist/js/bootstrap.bundle.min.js"
    toWidget
      [julius|
function loadProgramInfo() {
    fetch('@{DataR}?type=program-info')
        .then(response => response.json())
        .then(data => {
            document.getElementById('program-dynamic-content').innerHTML = 
                '<div class="alert alert-info"><h4>Program Information</h4><p>' + data.message + '</p></div>';
        });
}

function updateStats() {
    // Simulate loading stats
    document.getElementById('active-users').textContent = Math.floor(Math.random() * 1000);
    document.getElementById('total-programs').textContent = Math.floor(Math.random() * 50);
    document.getElementById('success-rate').textContent = Math.floor(Math.random() * 100) + '%';
}

// Load initial stats
document.addEventListener('DOMContentLoaded', function() {
    updateStats();
});
|]

-- API endpoint for dynamic data
getDataR :: Handler Value
getDataR = do
  mDataType <- lookupGetParam "type"
  case mDataType of
    Just "home" ->
      returnJson
        $ object
            [ "message"
                .= ("Welcome to the home page! Data loaded successfully from Render." :: String)
            ]
    Just "program" ->
      returnJson
        $ object
            [ "message"
                .= ("Program data loaded successfully from Render." :: String)
            ]
    Just "program-info" ->
      returnJson
        $ object
            [ "message"
                .= ("Program information: This is a comprehensive program management system running on Render with real-time capabilities." :: String)
            ]
    _ -> returnJson $ object ["message" .= ("Unknown data type" :: String)]

-- Main function with environment variable support
main :: IO ()
main = do
    -- Get port from environment variable (Render sets this)
  portStr <- lookupEnv "PORT"
  let port = maybe 3000 id (portStr >>= readMaybe)
    -- Create static file serving
  static' <- static "static"
    -- Create the application
  let app = App static'
  putStrLn $ "Starting Yesod SPA on port " ++ show port
    -- Run the application
  waiApp <- toWaiApp app
  run port waiApp
