<?php

namespace App\Controller;

use App\Repository\UserRepository;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Annotation\Route;

class TestController extends AbstractController
{
    #[Route('/test', name: 'app_test')]
    public function index(UserRepository $userRepository): Response
    {
        return $this->render('test/index.html.twig', [
            'controller_name' => 'TestController',
            'users' => $userRepository->findAll(),
        ]);
    }
    #[Route('/sendMail', name: 'app_send_mail')]
    public function sendMail(): Response
    {
        mail('rollandbaptiste@hotmail.com', 'Test envoi de mail sujet', 'Test envoi de mail message');

        return $this->render('home/index.html.twig', [
            'controller_name' => 'TestController',
        ]);
    }
}
